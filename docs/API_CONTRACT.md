
# GlucoSafe API Contract

## Base URL

Local development:
http://localhost:3000/api

Untuk Flutter Android Emulator, gunakan:
http://10.0.2.2:3000/api

Untuk perangkat fisik, gunakan IP lokal komputer backend.
Semua perangkat harus terhubung ke jaringan yang dapat saling
mengakses.

## Format Response

Semua response JSON menggunakan format berikut:

{
  "success": true,
  "message": "Request berhasil",
  "data": {}
}

## 1. Health Check

GET /health

Auth: Tidak diperlukan

## 2. Register

POST /auth/register

Auth: Tidak diperlukan

Request:
{
  "name": "Nama Pengguna",
  "email": "user@example.com",
  "password": "Password123!"
}

Success: 201 Created

## 3. Login

POST /auth/login

Auth: Tidak diperlukan

Request:
{
  "email": "user@example.com",
  "password": "Password123!"
}

Success response:
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "<JWT_TOKEN>",
    "user": {
      "id": 1,
      "name": "Nama Pengguna",
      "email": "user@example.com"
    }
  }
}

Simpan token dengan aman di aplikasi Flutter.

## 4. Get Current User

GET /users/me

Auth:
Authorization: Bearer <JWT_TOKEN>

Mengembalikan profil pengguna yang sedang login.

## 5. Get Screening History

GET /screenings

Auth:
Authorization: Bearer <JWT_TOKEN>

Mengembalikan riwayat screening milik pengguna yang login.

## 6. Get Screening Detail

GET /screenings/:id

Auth:
Authorization: Bearer <JWT_TOKEN>

Mengembalikan detail hasil screening milik pengguna yang login.

## 7. Get Screening Recommendations

GET /screenings/:id/recommendations

Auth:
Authorization: Bearer <JWT_TOKEN>

Mengembalikan rekomendasi yang terkait dengan hasil screening.

## Authentication

Endpoint yang dilindungi membutuhkan JWT pada header:

Authorization: Bearer <JWT_TOKEN>

Jangan mengirim password atau JWT di URL.

## Error Responses

400 Bad Request:
Input tidak valid.

401 Unauthorized:
Token tidak ada, tidak valid, atau kedaluwarsa.

404 Not Found:
Resource tidak ditemukan atau tidak dapat diakses pengguna.

409 Conflict:
Email sudah terdaftar.

500 Internal Server Error:
Terjadi kesalahan pada server.

## Screening Prediction Status

POST /screenings belum tersedia.

Endpoint pembuatan screening akan diimplementasikan setelah kontrak
integrasi dengan model machine learning disepakati.

Jangan membuat atau menampilkan hasil prediksi dummy sebagai hasil
screening yang sebenarnya.
