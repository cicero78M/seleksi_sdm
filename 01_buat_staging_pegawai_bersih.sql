-- Membuat salinan staging dengan normalisasi nama dan status validasi.
-- Data yang tidak dapat dipastikan tidak diisi otomatis.

DROP TABLE IF EXISTS staging_pegawai_bersih;

CREATE TABLE staging_pegawai_bersih AS
WITH s AS (
    SELECT
        row_number() OVER () AS baris,
        nip, nik,
        CASE WHEN nama IS NULL OR btrim(nama) = '' THEN nama
             ELSE initcap(regexp_replace(btrim(nama), '[[:space:]]+', ' ', 'g')) END AS nama,
        tanggal_lahir, tanggal_masuk, kode_unit, golongan
    FROM staging_pegawai
), v AS (
    SELECT s.*,
           array_remove(ARRAY[
             CASE WHEN NULLIF(btrim(nip), '') IS NULL THEN 'NIP kosong'
                  WHEN btrim(nip) !~ '^[0-9]{18}$' THEN 'NIP bukan 18 digit angka' END,
             CASE WHEN NULLIF(btrim(nik), '') IS NULL THEN 'NIK kosong'
                  WHEN btrim(nik) !~ '^[0-9]{16}$' THEN 'NIK bukan 16 digit angka' END,
             CASE WHEN NULLIF(btrim(nama), '') IS NULL THEN 'Nama kosong'
                  WHEN nama !~ '^[A-Z][a-z]*( [A-Z][a-z]*)*$'
                    THEN 'Nama tidak sesuai kapital awal/spasi ganda' END,
             CASE WHEN NULLIF(btrim(tanggal_lahir), '') IS NULL THEN 'Tanggal lahir kosong'
                  WHEN btrim(tanggal_lahir) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                    THEN 'Tanggal lahir bukan YYYY-MM-DD' END,
             CASE WHEN NULLIF(btrim(tanggal_masuk), '') IS NULL THEN 'Tanggal masuk kosong'
                  WHEN btrim(tanggal_masuk) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                    THEN 'Tanggal masuk bukan YYYY-MM-DD' END,
             CASE WHEN NULLIF(btrim(kode_unit), '') IS NULL THEN 'Kode unit kosong'
                  WHEN NOT EXISTS (SELECT 1 FROM unit_kerja u
                                   WHERE u.id_unit::text = btrim(s.kode_unit))
                    THEN 'Kode unit tidak ada di master' END,
             CASE WHEN NULLIF(btrim(golongan), '') IS NULL THEN 'Golongan kosong'
                  WHEN NOT EXISTS (SELECT 1 FROM golongan g
                                   WHERE g.kode_golongan = btrim(s.golongan))
                    THEN 'Golongan tidak ada di master' END,
             CASE WHEN btrim(tanggal_lahir) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                       AND btrim(tanggal_masuk) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                       AND btrim(tanggal_masuk)::date < btrim(tanggal_lahir)::date + interval '17 years'
                    THEN 'Tanggal masuk kurang dari 17 tahun setelah lahir' END
           ], NULL) AS masalah
    FROM s
)
SELECT v.*, CASE WHEN cardinality(masalah) = 0 THEN 'VALID' ELSE 'TINDAK_LANJUT' END AS status_validasi
FROM v;

CREATE INDEX IF NOT EXISTS ix_staging_pegawai_bersih_status
    ON staging_pegawai_bersih (status_validasi);
