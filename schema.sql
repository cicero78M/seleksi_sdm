CREATE TABLE unit_kerja (
    id_unit INT PRIMARY KEY,
    nama_unit VARCHAR(100) NOT NULL,
    id_unit_induk INT REFERENCES unit_kerja (id_unit)
);

CREATE TABLE golongan (
    id_golongan INT PRIMARY KEY,
    kode_golongan VARCHAR(5) NOT NULL UNIQUE,
    nama_pangkat VARCHAR(50) NOT NULL
);

CREATE TABLE jabatan (
    id_jabatan INT PRIMARY KEY,
    nama_jabatan VARCHAR(100) NOT NULL,
    jenis_jabatan VARCHAR(20) NOT NULL
);

CREATE TABLE pegawai (
    id_pegawai INT PRIMARY KEY,
    nip CHAR(18) NOT NULL UNIQUE,
    nik CHAR(16) NOT NULL UNIQUE,
    nama VARCHAR(100) NOT NULL,
    jenis_kelamin CHAR(1) NOT NULL CHECK (jenis_kelamin IN ('L','P')),
    tempat_lahir VARCHAR(50),
    tanggal_lahir DATE NOT NULL,
    tanggal_masuk DATE NOT NULL,
    id_unit INT NOT NULL REFERENCES unit_kerja (id_unit),
    id_jabatan INT NOT NULL REFERENCES jabatan (id_jabatan),
    id_golongan INT NOT NULL REFERENCES golongan (id_golongan),
    id_atasan INT REFERENCES pegawai (id_pegawai),
    status_pegawai VARCHAR(15) NOT NULL DEFAULT 'AKTIF',
    batas_usia_pensiun SMALLINT NOT NULL DEFAULT 58,
    CHECK (tanggal_masuk > tanggal_lahir)
);

CREATE TABLE riwayat_pendidikan (
    id_pendidikan INT PRIMARY KEY,
    id_pegawai INT NOT NULL REFERENCES pegawai (id_pegawai),
    jenjang VARCHAR(10) NOT NULL,
    institusi VARCHAR(100),
    jurusan VARCHAR(100),
    tahun_lulus SMALLINT
);

CREATE TABLE diklat (
    id_diklat INT PRIMARY KEY,
    nama_diklat VARCHAR(150) NOT NULL,
    penyelenggara VARCHAR(100),
    jam_pelajaran SMALLINT
);

CREATE TABLE riwayat_diklat (
    id_riwayat_diklat INT PRIMARY KEY,
    id_pegawai INT NOT NULL REFERENCES pegawai (id_pegawai),
    id_diklat INT NOT NULL REFERENCES diklat (id_diklat),
    tanggal_mulai DATE,
    tanggal_selesai DATE,
    nilai NUMERIC(5,2)
);

CREATE TABLE riwayat_mutasi (
    id_mutasi INT PRIMARY KEY,
    id_pegawai INT NOT NULL REFERENCES pegawai (id_pegawai),
    id_unit_lama INT REFERENCES unit_kerja (id_unit),
    id_unit_baru INT NOT NULL REFERENCES unit_kerja (id_unit),
    nomor_sk VARCHAR(50),
    tanggal_sk DATE,
    tmt_mutasi DATE NOT NULL
);

CREATE TABLE staging_pegawai (
    nip VARCHAR(30),
    nik VARCHAR(30),
    nama VARCHAR(150),
    tanggal_lahir VARCHAR(30),
    tanggal_masuk VARCHAR(30),
    kode_unit VARCHAR(20),
    golongan VARCHAR(10)
);
