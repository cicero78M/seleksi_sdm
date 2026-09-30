-- Menampilkan mutasi pertama setiap personil berdasarkan TMT mutasi.
-- Mutasi yang memiliki tanggal sama diurutkan dengan id_mutasi.

SELECT p.nip,
       p.nama,
       rm.id_mutasi,
       rm.tmt_mutasi,
       rm.tanggal_sk,
       rm.nomor_sk,
       u_lama.nama_unit AS unit_lama,
       u_baru.nama_unit AS unit_baru
FROM pegawai p
JOIN (
    SELECT x.*,
           row_number() OVER (
               PARTITION BY x.id_pegawai
               ORDER BY x.tmt_mutasi ASC, x.id_mutasi ASC
           ) AS urutan_mutasi
    FROM riwayat_mutasi x
) rm ON rm.id_pegawai = p.id_pegawai AND rm.urutan_mutasi = 1
LEFT JOIN unit_kerja u_lama ON u_lama.id_unit = rm.id_unit_lama
JOIN unit_kerja u_baru ON u_baru.id_unit = rm.id_unit_baru
ORDER BY p.nama, p.nip;
