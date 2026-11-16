
const fs = require('fs');
const mysql = require('mysql2/promise');
require('dotenv').config();

// TiDB Cloud mewajibkan TLS. SSL aktif kalau DB_SSL_CA di-set:
// - isi dengan path file CA -> verifikasi sertifikat penuh
// - isi "true" -> TLS standar (pakai CA sistem)
// Kosong -> koneksi plain (localhost/dev).
const caValue = process.env.DB_SSL_CA;
const sslConfig = caValue
  ? { minVersion: 'TLSv1.2', ...(caValue !== 'true' ? { ca: fs.readFileSync(caValue) } : {}) }
  : process.env.DB_SSL_DISABLED === 'true'
    ? undefined
    : { minVersion: 'TLSv1.2' };

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  ...(sslConfig ? { ssl: sslConfig } : {}),
});

module.exports = pool;
