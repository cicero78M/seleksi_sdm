# Basic Data Skill

Kumpulan skema basis data, migrasi, dan query SQL untuk pengolahan data
kepegawaian. Proyek ini berisi kode dan struktur yang aman untuk dibagikan;
data pegawai asli, CSV, workbook, dan hasil grafik tidak disimpan di repositori.

## Isi proyek

- `schema.sql` — definisi tabel utama.
- `db/migrations/001_init.sql` — migrasi awal basis data.
- `01_buat_staging_pegawai_bersih.sql` — membuat tabel staging yang bersih.
- `02_daftar_temuan_staging.sql` — mencatat temuan atau masalah data.
- `03_log_perubahan_staging.sql` — mencatat perubahan pada data staging.
- `04_mutasi_pertama_personil.sql` — laporan mutasi personel.
- `05_pegawai_belum_pernah_diklat.sql` — mencari pegawai yang belum pernah mengikuti diklat.
- `buat_laporan_excel.js` — skrip pembuatan laporan Excel dari sumber data lokal.
- `package.json` dan `package-lock.json` — dependensi skrip JavaScript.

## Kebutuhan

- PostgreSQL.
- Node.js dan npm, jika ingin menjalankan skrip laporan.

## Menjalankan query

1. Buat basis data PostgreSQL kosong.
2. Jalankan `schema.sql` atau migrasi pada folder `db/migrations`.
3. Jalankan query laporan sesuai kebutuhan.

Contoh dengan `psql`:

```bash
psql -d nama_database -f schema.sql
psql -d nama_database -f 01_buat_staging_pegawai_bersih.sql
```

## Menjalankan skrip laporan

```bash
npm install
node buat_laporan_excel.js
```

Sesuaikan koneksi database melalui konfigurasi lokal. Jangan menaruh password,
NIP, NIK, nama pegawai, atau data pribadi di dalam repositori.

## Catatan keamanan

Repositori ini hanya memuat kode, skema, migrasi, dan dokumentasi. Berkas data
pribadi, data produksi, file CSV, workbook, grafik, arsip, serta kredensial
harus tetap berada di luar repositori dan sudah diabaikan oleh `.gitignore`.

## Prototype aplikasi SDM

Dokumentasi backend RAG dan jalur LiteLLM ada di [Backend_SDM_RAG/README.md](Backend_SDM_RAG/README.md). Backend tersebut memakai alias LiteLLM `copilot-rag` yang diarahkan ke model GitHub Copilot terkonfigurasi; embedding RAG tetap lokal dengan Transformers.js.

Folder `Backend_SDM_Test/` dan `Frontend_SDM_Test/` membentuk prototype aplikasi
Merit System Personel Polri:

- **Dashboard visualisasi data personel** — ringkasan status, golongan/pangkat POLRI dan ASN,
  jenjang pendidikan, kelompok jabatan/nivelering, kelompok usia, lama dinas,
  proyeksi pensiun, riwayat diklat/mutasi berulang, serta kualitas dan kesiapan data.
- **Data Personel** — daftar berbasis scope, pencarian, pagination, tambah, dan
  update data personel.
- **Profil Personel** — satu drawer dengan tab Ringkasan, Riwayat Jabatan, serta
  Pendidikan & Diklat.
- **Riwayat Jabatan** — timeline kronologis dengan tambah, edit, hapus, Satker,
  Unsur Pembantu Pimpinan, jabatan berbasis unit, nivelering, status, dan tanggal
  penugasan. Untuk operator Polres, Satker otomatis mengikuti Satker personel.
- **Pendidikan & Diklat** — input terpisah untuk pendidikan dan diklat; data
  dibaca melalui backend dan mengikuti validasi serta scope.
- **Administrasi Scope Organisasi** — admin menetapkan Satker yang dapat diakses
  operator.
- **Administrasi Akses** — admin pertama melihat registrasi pending, menyetujui atau
  menolak pendaftaran, menetapkan role, dan melihat riwayat persetujuan. Approval
  tetap dibatasi backend hanya untuk role `admin` pertama.
- **Navigasi akun** — menu utama berurutan Visualisasi Data, Data Personel, Profil
  Saya, Scope Organisasi (admin), dan Log Aktivitas. Ganti password tersedia di
  halaman Profil Saya, sedangkan Log Aktivitas memiliki filter responsif.
- **Authentication dan akses** — login JWT, role, scope organisasi, audit, dan
  ganti password.

### Kredensial demo

Akun berikut dibuat oleh seed `Backend_SDM_Test/db/seed/demo_merit_system.sql`.
Gunakan hanya pada lingkungan demo/non-produksi:

| Role | Username | Password |
|---|---|---|
| Admin SSDM | `demo_admin_ssdm` | `Demo-Admin-2026!` |
| Operator Polda | `demo_operator_polda` | `Demo-Operator-2026!` |
| Operator Satker | `demo_operator_satker` | `Demo-Operator-2026!` |

Jalankan seed demo dari direktori backend dengan `psql "$DATABASE_URL" -f db/seed/demo_merit_system.sql`.
Jangan gunakan atau menyebarkan kredensial ini pada lingkungan produksi.

Aturan penempatan riwayat jabatan mengikuti struktur pada **Update Data**:
`BAG*`, `SAT*`, `SI*`, dan `POLSEK` beserta parent sampai unit terkecil.
Jabatan hanya dimuat setelah unit dipilih dan harus memiliki mapping aktif pada
unit tersebut; mapping `legacy-assignment` ditolak oleh backend.

Aturan identitas pada form: hanya jenis personel yang dipilih; POLRI otomatis
menggunakan NRP, sedangkan ASN/PPPK/HONORER/LAINNYA otomatis menggunakan NIP.
Detail instalasi dan endpoint ada di README masing-masing subproyek.
