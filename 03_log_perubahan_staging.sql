-- Mencatat perubahan objektif pada nama: trim, spasi ganda menjadi satu,
-- dan kapital awal kata. Nilai kosong tidak diisi.

DROP TABLE IF EXISTS log_perubahan_staging;

CREATE TABLE log_perubahan_staging (
    id bigserial PRIMARY KEY,
    waktu timestamptz NOT NULL DEFAULT now(),
    baris bigint NOT NULL,
    kolom text NOT NULL,
    nilai_lama text,
    nilai_baru text,
    alasan text NOT NULL
);

INSERT INTO log_perubahan_staging (baris, kolom, nilai_lama, nilai_baru, alasan)
SELECT row_number() OVER () AS baris,
       'nama', s.nama,
       initcap(regexp_replace(btrim(s.nama), '[[:space:]]+', ' ', 'g')),
       'Normalisasi spasi dan kapital awal setiap kata'
FROM staging_pegawai s
WHERE s.nama IS NOT NULL
  AND s.nama IS DISTINCT FROM initcap(regexp_replace(btrim(s.nama), '[[:space:]]+', ' ', 'g'));

SELECT id, waktu, baris, kolom, nilai_lama, nilai_baru, alasan
FROM log_perubahan_staging
ORDER BY id;
