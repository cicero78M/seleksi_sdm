-- Menyusun seluruh baris staging yang tidak memenuhi aturan validasi.

DROP TABLE IF EXISTS daftar_temuan_staging;

CREATE TABLE daftar_temuan_staging AS
SELECT baris, nip, nik, nama, tanggal_lahir, tanggal_masuk,
       kode_unit, golongan, status_validasi, masalah
FROM staging_pegawai_bersih
WHERE status_validasi = 'TINDAK_LANJUT';

CREATE INDEX IF NOT EXISTS ix_daftar_temuan_staging_baris
    ON daftar_temuan_staging (baris);

-- Hasil pemeriksaan:
SELECT * FROM daftar_temuan_staging ORDER BY baris;
