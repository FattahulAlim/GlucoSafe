# GlucoSafe: Website Flask & API Machine Learning

Website pengujian model dan penyedia API machine learning untuk tim GlucoSafe dan aplikasi mobile Flutter, dibangun sesuai spesifikasi **PRD_GlucoSafe.md versi 1.3** dan acuan visual **design.md**.

## Fitur Utama

1. **Website Satu Halaman (`GET /`)**
   - Header ringkas dengan status model aktual dari backend.
   - Form data masukan 15 fitur (BRFSS 2015) untuk 1 data per permintaan (tanpa upload CSV/batch sesuai batasan MVP).
   - Validasi langsung di sisi klien dan sisi server dengan fokus keyboard otomatis ke kesalahan pertama.
   - Area hasil prediksi: label keluaran model, versi model, skor (bila tersedia), dan ringkasan data yang diuji.
   - Keterangan tegas bahwa hasil adalah prediksi model, bukan diagnosis medis.
   - Deteksi perubahan input setelah prediksi sukses: otomatis menandai data berubah agar hasil tidak tertukar.

2. **API JSON Terpadu**
   - `GET /api/health`: Memeriksa kesiapan layanan dan artefak model (`model_ready`, `model_version`, daftar fitur).
   - `POST /api/predict`: Menerima `{ "features": { ... } }`, memvalidasi tipe/rentang nilai, menjalankan model terlatih, mengembalikan `{ "success": true, "prediction": "...", "model_version": "...", "score": ... }`.
   - Kode status HTTP presisi:
     - `200`: Berhasil diproses
     - `400`: Input tidak valid (`VALIDATION_ERROR`, rincian per field)
     - `415`: Format bukan application/json (`UNSUPPORTED_MEDIA_TYPE`)
     - `503`: Model belum tersedia (`MODEL_NOT_READY`, tanpa hasil palsu)
     - `500`: Kesalahan internal server (tanpa membocorkan traceback)

3. **Desain Terarah (design.md & antislop)**
   - Gaya formulir kerja terstruktur: `ENERGY 1 / RHYTHM 2 / MOTION 1`.
   - Palet warna fokus: Teal `#006B63` sebagai aksen tunggal, merah `#A32626` khusus kesalahan, latar tenang `#F5F7F8`.
   - Tanpa bayangan mengambang, tanpa gradien mencolok, tanpa border radius pil berlebihan, tanpa teks em dash.
   - Tata letak 3:2 pada desktop, reflow otomatis 1 kolom pada layar kecil.

## Menjalankan Aplikasi

```powershell
cd "D:\KULIAH\Semester 5\Project Base Learning\web-flask"
.\.venv\Scripts\python.exe app.py
```

Akses di browser:
- Halaman web: `http://localhost:5000/`
- Cek kesehatan model: `http://localhost:5000/api/health`

## Menjalankan Pengujian

```powershell
cd "D:\KULIAH\Semester 5\Project Base Learning\web-flask"
.\.venv\Scripts\python.exe -m pytest tests -q
```
Semua 10 skenario pengujian mencakup penanganan 415, 400, 503, validasi 15 field, hitung BMI otomatis, integrasi model mock, dan render template.
