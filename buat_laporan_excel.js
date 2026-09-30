const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');
const sharp = require('sharp');

const root = __dirname;
const seed = path.join(root, 'media/inbound/openclaw-staged-fa9ed81f-b382-40f9-878d-0a1f4f93b443/input-seed_data---fe90ea47-d060-4a2a-84c2-e9ab95ed343d.sql');
const sql = fs.readFileSync(seed, 'utf8');

function section(marker) {
  const start = sql.indexOf(marker);
  if (start < 0) throw new Error('Bagian SQL tidak ditemukan: ' + marker);
  const end = sql.indexOf(';', start);
  return sql.slice(start, end);
}
function parseValue(v) {
  v = v.trim();
  if (v === 'NULL') return null;
  const date = v.match(/^DATE\s+'([^']+)'$/);
  if (date) return date[1];
  if (v.startsWith("'") && v.endsWith("'")) return v.slice(1, -1).replace(/''/g, "'");
  return /^-?\d+(\.\d+)?$/.test(v) ? Number(v) : v;
}
function parseRows(text) {
  const body = text.slice(text.indexOf('VALUES') + 6);
  const rows = [];
  let cur = '', quote = false, depth = 0;
  for (const ch of body) {
    if (ch === "'") quote = !quote;
    if (!quote && ch === '(') { depth++; cur = ''; continue; }
    if (!quote && ch === ')') { depth--; if (depth === 0) { rows.push(splitFields(cur).map(parseValue)); cur = ''; continue; } }
    if (depth > 0) cur += ch;
  }
  return rows;
}
function splitFields(s) {
  const a = []; let cur = '', quote = false;
  for (const ch of s) {
    if (ch === "'") quote = !quote;
    if (ch === ',' && !quote) { a.push(cur); cur = ''; } else cur += ch;
  }
  a.push(cur); return a;
}
const units = parseRows(section('INSERT INTO unit_kerja'));
const golongan = parseRows(section('INSERT INTO golongan'));
const pegawai = [];
for (let pos = 0; pos >= 0; ) {
  pos = sql.indexOf('INSERT INTO pegawai', pos);
  if (pos < 0) break;
  const end = sql.indexOf(';', pos);
  parseRows(sql.slice(pos, end)).forEach(r => pegawai.push(r));
  pos = end + 1;
}
if (pegawai.length !== 300) throw new Error('Jumlah pegawai terbaca ' + pegawai.length + ', seharusnya 300');

const asOf = new Date('2026-09-30T00:00:00Z');
function yearsBetween(from) {
  const d = new Date(from + 'T00:00:00Z');
  let n = asOf.getUTCFullYear() - d.getUTCFullYear();
  if (asOf.getUTCMonth() < d.getUTCMonth() || (asOf.getUTCMonth() === d.getUTCMonth() && asOf.getUTCDate() < d.getUTCDate())) n--;
  return n;
}
function ageGroup(age) { return age < 30 ? '<30' : age < 40 ? '30-39' : age < 50 ? '40-49' : '>=50'; }
const unitMap = new Map(units.map(r => [Number(r[0]), r[1]]));
const golMap = new Map(golongan.map(r => [Number(r[0]), r[1]]));
const records = pegawai.map(r => ({
  id: r[0], nip: String(r[1]), nik: String(r[2]), nama: r[3], jk: r[4], lahir: r[6], masuk: r[7], kode: r[8],
  unit: unitMap.get(Number(r[8])), gol: golMap.get(Number(r[10])), age: yearsBetween(r[6]), tenure: yearsBetween(r[7])
}));
const count = (arr, key) => arr.reduce((m, x) => (m[x[key]] = (m[x[key]] || 0) + 1, m), {});
const golJk = {}; records.forEach(r => { golJk[r.gol] ||= { L: 0, P: 0 }; golJk[r.gol][r.jk]++; });
const ageCounts = count(records.map(r => ({g: ageGroup(r.age)})), 'g');
const orderedGol = golongan.map(r => r[1]).filter(g => golJk[g]);
const orderedAge = ['<30', '30-39', '40-49', '>=50'];

function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
function barSvg(title, labels, series, colors, yLabel) {
  const W = 1100, H = 560, left = 90, bottom = 110, top = 70, plotW = W-left-35, plotH = H-top-bottom;
  const max = Math.max(...series.flatMap(s => s.values), 1), groupW = plotW / labels.length, barW = Math.min(28, groupW/(series.length+1));
  let out = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="100%" height="100%" fill="white"/><text x="${W/2}" y="35" text-anchor="middle" font-family="Arial" font-size="22" font-weight="bold">${esc(title)}</text>`;
  for (let i=0;i<=5;i++) { const y=top+plotH-i*plotH/5, val=Math.round(max*i/5); out += `<line x1="${left}" y1="${y}" x2="${W-35}" y2="${y}" stroke="#ddd"/><text x="${left-10}" y="${y+5}" text-anchor="end" font-family="Arial" font-size="12">${val}</text>`; }
  labels.forEach((lab,i) => { const x0=left+i*groupW; out += `<text x="${x0+groupW/2}" y="${H-65}" text-anchor="middle" font-family="Arial" font-size="12">${esc(lab)}</text>`; series.forEach((s,j)=>{const v=s.values[i]||0,h=v/max*plotH,x=x0+groupW/2+(j-(series.length-1)/2)*barW; out += `<rect x="${x-barW/2}" y="${top+plotH-h}" width="${barW-3}" height="${h}" fill="${colors[j]}"/><text x="${x}" y="${top+plotH-h-5}" text-anchor="middle" font-family="Arial" font-size="10">${v}</text>`;}); });
  series.forEach((s,i)=>{const x=left+i*180; out += `<rect x="${x}" y="${H-35}" width="15" height="15" fill="${colors[i]}"/><text x="${x+22}" y="${H-22}" font-family="Arial" font-size="12">${esc(s.name)}</text>`;});
  out += `<text transform="translate(20 ${H/2}) rotate(-90)" text-anchor="middle" font-family="Arial" font-size="13">${esc(yLabel)}</text></svg>`; return out;
}
const chart1 = path.join(root, 'grafik_golongan_jenis_kelamin.svg');
const chart2 = path.join(root, 'grafik_kelompok_usia.svg');
fs.writeFileSync(chart1, barSvg('Jumlah Pegawai per Golongan dan Jenis Kelamin', orderedGol, [{name:'Laki-laki', values:orderedGol.map(g=>golJk[g].L)},{name:'Perempuan', values:orderedGol.map(g=>golJk[g].P)}], ['#2f75b5','#ed7d31'], 'Jumlah Pegawai'));
fs.writeFileSync(chart2, barSvg('Komposisi Pegawai Berdasarkan Kelompok Usia', orderedAge, [{name:'Jumlah Pegawai', values:orderedAge.map(g=>ageCounts[g]||0)}], ['#70ad47'], 'Jumlah Pegawai'));

Promise.all([
  sharp(chart1).png().toFile(path.join(root, 'grafik_golongan_jenis_kelamin.png')),
  sharp(chart2).png().toFile(path.join(root, 'grafik_kelompok_usia.png'))
]).then(async () => {

const wb = new ExcelJS.Workbook(); wb.creator = 'Cicero'; wb.created = new Date();
const detail = wb.addWorksheet('Data Pegawai');
const master = wb.addWorksheet('Master Unit');
const rekap1 = wb.addWorksheet('Pivot Golongan JK');
const rekap2 = wb.addWorksheet('Pivot Kelompok Usia');
const grafik = wb.addWorksheet('Grafik');
const temuan = wb.addWorksheet('Temuan');
const headerFill = { type:'pattern', pattern:'solid', fgColor:{argb:'1F4E78'} };
const headerFont = { color:{argb:'FFFFFF'}, bold:true };
function styleHeader(row) { row.eachCell(c => { c.fill=headerFill; c.font=headerFont; c.alignment={vertical:'middle',horizontal:'center'}; }); row.height=24; }

master.addRow(['Kode Unit','Nama Unit']); styleHeader(master.getRow(1)); units.forEach(r=>master.addRow([r[0],r[1]])); master.columns=[{width:14},{width:42}]; master.autoFilter='A1:B16';
detail.addRow(['ID','NIP','NIK','Nama','Jenis Kelamin','Tanggal Lahir','Tanggal Masuk','Kode Unit','Nama Unit','Golongan','Usia (tahun)','Masa Kerja (tahun)','Kelompok Usia','Status Pegawai']); styleHeader(detail.getRow(1));
records.forEach((r,i)=>{ const n=i+2; detail.addRow([r.id,r.nip,r.nik,r.nama,r.jk,new Date(r.lahir),new Date(r.masuk),r.kode,{formula:`XLOOKUP(H${n},'Master Unit'!$A$2:$A$16,'Master Unit'!$B$2:$B$16,"Tidak ditemukan")`},r.gol,{formula:`DATEDIF(F${n},TODAY(),"Y")`},{formula:`DATEDIF(G${n},TODAY(),"Y")`},{formula:`IF(K${n}<30,"<30",IF(K${n}<40,"30-39",IF(K${n}<50,"40-49",">=50")))`},'AKTIF']); });
detail.columns=[{width:8},{width:21},{width:19},{width:28},{width:14},{width:15},{width:15},{width:12},{width:42},{width:12},{width:14},{width:18},{width:16},{width:14}];
detail.getColumn(6).numFmt='yyyy-mm-dd'; detail.getColumn(7).numFmt='yyyy-mm-dd'; detail.autoFilter='A1:N301'; detail.views=[{state:'frozen',ySplit:1}];

rekap1.addRow(['Golongan','Laki-laki','Perempuan','Total']); styleHeader(rekap1.getRow(1)); orderedGol.forEach(g=>rekap1.addRow([g,golJk[g].L,golJk[g].P,golJk[g].L+golJk[g].P])); rekap1.addRow(['TOTAL',records.filter(r=>r.jk==='L').length,records.filter(r=>r.jk==='P').length,records.length]); rekap1.columns=[{width:14},{width:15},{width:15},{width:12}];
rekap2.addRow(['Kelompok Usia','Jumlah Pegawai','Persentase']); styleHeader(rekap2.getRow(1)); orderedAge.forEach(g=>rekap2.addRow([g,ageCounts[g]||0,(ageCounts[g]||0)/records.length])); rekap2.addRow(['TOTAL',records.length,1]); rekap2.getColumn(3).numFmt='0.00%'; rekap2.columns=[{width:18},{width:18},{width:15}];

grafik.addImage(wb.addImage({filename:path.join(root, 'grafik_golongan_jenis_kelamin.png'), extension:'png'}), 'A1:J20'); grafik.addImage(wb.addImage({filename:path.join(root, 'grafik_kelompok_usia.png'), extension:'png'}), 'A22:J41'); grafik.getColumn(1).width=3;
temuan.addRow(['RINGKASAN TEMUAN PIMPINAN']); temuan.getRow(1).font={bold:true,size:16,color:{argb:'1F4E78'}};
const topGol = orderedGol.slice().sort((a,b)=>(golJk[b].L+golJk[b].P)-(golJk[a].L+golJk[a].P))[0]; const topAge = orderedAge.slice().sort((a,b)=>(ageCounts[b]||0)-(ageCounts[a]||0))[0];
temuan.addRow(['Jumlah pegawai dianalisis', records.length]);
temuan.addRow([`1. Golongan terbanyak adalah ${topGol}, sebanyak ${golJk[topGol].L+golJk[topGol].P} pegawai (L: ${golJk[topGol].L}, P: ${golJk[topGol].P}).`]);
temuan.addRow([`2. Kelompok usia terbanyak adalah ${topAge}, sebanyak ${ageCounts[topAge]} pegawai (${(ageCounts[topAge]/records.length*100).toFixed(2)}%).`]);
temuan.addRow([`3. Rata-rata masa kerja pegawai adalah ${(records.reduce((s,r)=>s+r.tenure,0)/records.length).toFixed(1)} tahun; data ini dapat menjadi dasar perencanaan regenerasi dan pengembangan kompetensi.`]);
temuan.getColumn(1).width=120; temuan.getColumn(2).width=18; temuan.getColumn(1).alignment={wrapText:true,vertical:'top'}; temuan.eachRow((row,i)=>{if(i>1) row.height=32;});

for (const ws of [detail,master,rekap1,rekap2,temuan]) ws.eachRow(row=>row.eachCell(c=>{c.alignment={...c.alignment,vertical:'center'};}));
const out = path.join(root, 'laporan_pelaporan_analisis_pegawai.xlsx');
await wb.xlsx.writeFile(out); console.log(JSON.stringify({out,pegawai:records.length,topGol,topAge,ageCounts,unitCount:units.length},null,2));
}).catch(err => { console.error(err); process.exitCode = 1; });
