-- Menampilkan pegawai yang belum memiliki satu pun riwayat diklat.

SELECT p.id_pegawai,
       p.nip,
       p.nik,
       p.nama,
       p.tanggal_masuk,
       p.status_pegawai
FROM pegawai p
WHERE NOT EXISTS (
    SELECT 1
    FROM riwayat_diklat rd
    WHERE rd.id_pegawai = p.id_pegawai
)
ORDER BY p.nama, p.nip;
