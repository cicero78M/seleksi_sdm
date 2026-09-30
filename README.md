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
