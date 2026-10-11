-- ============================================================
--  GlucoSafe — SQL Schema
--  Database   : MySQL / MariaDB
--  Encoding   : utf8mb4
--  Dibuat      : 2026
-- ============================================================

CREATE DATABASE IF NOT EXISTS glucosafe
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE glucosafe;

-- ------------------------------------------------------------
-- 1. TABEL users
--    Menyimpan akun pengguna (login & register)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  name        VARCHAR(100)    NOT NULL,
  email       VARCHAR(150)    NOT NULL,
  password    VARCHAR(255)    NOT NULL,          -- bcrypt hash
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE  KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
-- 2. TABEL screening_results
--    Menyimpan setiap hasil skrining yang dilakukan pengguna.
--    15 fitur BRFSS 2015 + BMI + hasil prediksi ML.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS screening_results (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  user_id     INT UNSIGNED    NOT NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Hasil prediksi dari ML API
  risk_percent  DECIMAL(5,2)  NOT NULL COMMENT 'Persentase risiko diabetes 0-100',
  risk_label    ENUM('Rendah','Sedang','Tinggi') NOT NULL,

  -- Step 1: Data Diri
  sex         TINYINT(1)      NOT NULL COMMENT '0=Perempuan, 1=Laki-laki',
  age         TINYINT         NOT NULL COMMENT 'Kode usia 1-13 (BRFSS)',
  height_cm   DECIMAL(5,2)    NOT NULL COMMENT 'Tinggi badan (cm)',
  weight_kg   DECIMAL(5,2)    NOT NULL COMMENT 'Berat badan (kg)',
  bmi         DECIMAL(4,1)    NOT NULL COMMENT 'BMI = weight / (height_m^2)',

  -- Step 2: Riwayat Kesehatan (0=Tidak, 1=Ya)
  high_bp           TINYINT(1) NOT NULL COMMENT 'Tekanan darah tinggi',
  high_chol         TINYINT(1) NOT NULL COMMENT 'Kolesterol tinggi',
  stroke            TINYINT(1) NOT NULL COMMENT 'Riwayat stroke',
  heart_disease     TINYINT(1) NOT NULL COMMENT 'Riwayat penyakit jantung',
  diff_walk         TINYINT(1) NOT NULL COMMENT 'Kesulitan berjalan/naik tangga',

  -- Step 3: Kebiasaan Sehari-hari (0=Tidak, 1=Ya)
  smoker            TINYINT(1) NOT NULL COMMENT 'Pernah merokok ≥100 batang seumur hidup',
  phys_activity     TINYINT(1) NOT NULL COMMENT 'Aktivitas fisik 30 hari terakhir',
  fruits            TINYINT(1) NOT NULL COMMENT 'Konsumsi buah ≥1x per hari',
  veggies           TINYINT(1) NOT NULL COMMENT 'Konsumsi sayuran ≥1x per hari',

  -- Step 4: Kondisi Umum
  gen_hlth    TINYINT         NOT NULL COMMENT 'Kondisi kesehatan umum 1(Sangat Baik)-5(Buruk)',
  ment_hlth   TINYINT         NOT NULL COMMENT 'Jumlah hari buruk mental 0-30',
  phys_hlth   TINYINT         NOT NULL COMMENT 'Jumlah hari buruk fisik 0-30',

  PRIMARY KEY (id),
  CONSTRAINT fk_results_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  INDEX idx_results_user_id   (user_id),
  INDEX idx_results_created   (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
-- 3. TABEL recommendations
--    Rekomendasi yang dihasilkan per skrining.
--    Bisa diisi dari backend berdasarkan risk_label & fitur.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recommendations (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  result_id   INT UNSIGNED    NOT NULL,
  category    VARCHAR(50)     NOT NULL COMMENT 'Nutrisi | Aktivitas Fisik | Pemeriksaan',
  title       VARCHAR(150)    NOT NULL,
  description TEXT            NOT NULL,

  PRIMARY KEY (id),
  CONSTRAINT fk_rec_result
    FOREIGN KEY (result_id) REFERENCES screening_results(id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  INDEX idx_rec_result_id (result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
--  CONTOH DATA (opsional — hapus sebelum production)
-- ============================================================

-- User dummy
INSERT INTO users (name, email, password) VALUES
  ('Rahmawati', 'rahma@email.com', '$2b$12$dummy_hash_ganti_dengan_bcrypt');

-- Hasil skrining dummy
INSERT INTO screening_results (
  user_id, risk_percent, risk_label,
  sex, age, height_cm, weight_kg, bmi,
  high_bp, high_chol, stroke, heart_disease, diff_walk,
  smoker, phys_activity, fruits, veggies,
  gen_hlth, ment_hlth, phys_hlth
) VALUES (
  1, 28.00, 'Rendah',
  1, 5, 165.0, 70.0, 25.7,
  0, 0, 0, 0, 0,
  0, 1, 1, 1,
  2, 0, 0
);

-- Rekomendasi dummy untuk hasil di atas
INSERT INTO recommendations (result_id, category, title, description) VALUES
  (1, 'Nutrisi',         'Perbanyak Buah & Sayur',    'Konsumsi minimal 5 porsi buah dan sayuran setiap hari untuk menjaga kadar gula darah.'),
  (1, 'Aktivitas Fisik', 'Olahraga Rutin 30 Menit',   'Lakukan aktivitas aerobik sedang seperti jalan cepat selama 30 menit, minimal 5 hari per minggu.'),
  (1, 'Pemeriksaan',     'Cek Gula Darah Berkala',    'Lakukan pemeriksaan gula darah minimal sekali setahun meski belum ada gejala.');
