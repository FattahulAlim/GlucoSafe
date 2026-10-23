# GlucoSafe: Web Flask Pengolahan Dataset & Batch Inference

Layanan web untuk mengolah dataset CSV skala besar, menjalankan inferensi model ML
secara batch, lalu menyimpan hasilnya ke database MySQL agar dapat ditarik oleh
aplikasi mobile GlucoSafe.

## Alur Kerja

1. Admin mengunggah dataset CSV (format 15 fitur BRFSS 2015, hingga 500.000 baris).
2. Web Flask memvalidasi setiap baris dan menjalankan model secara chunked (`10.000` baris/chunk).
3. Hasil prediksi (`pred_label`, `pred_score`, `model_version`) ditulis ke CSV dan
   disimpan ke tabel `screening_results`.
4. Aplikasi mobile menarik riwayat/hasil melalui backend Node.js (`GET /api/screenings`).

### Penentuan `user_id` (Hybrid)

- Jika CSV memiliki kolom `user_id` (atau `UserId`, `userid`, `id_user`), nilai per baris dipakai.
- Jika kosong/tidak ada, dipakai **User ID Default** yang diisi pada form web.
- Baris tanpa `user_id` sama sekali tetap diolah, tetapi tidak disimpan ke database.

## Fitur

- Upload dataset CSV dengan pemrosesan streaming (hemat RAM) hingga 500.000 baris.
- Chunked batch inference dengan vektorisasi NumPy (`predict_matrix`).
- Validasi ketat 15 fitur + perhitungan BMI otomatis dari tinggi/berat badan.
- Penyimpanan otomatis ke MySQL (`screening_results`) dengan opsi checkbox pada form.
- Unduh CSV hasil prediksi lengkap (streaming dari disk).
- API JSON untuk integrasi mobile:
  - `GET /api/health`
  - `POST /api/predict` dengan payload `{ "features": { ... } }`

## Konfigurasi

Salin `.env.example` menjadi `.env`, lalu sesuaikan:

```ini
MODEL_DIR=model/artifacts
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=glucosafe
```

Letakkan artefak model (`model.joblib`, opsional `preprocessor.joblib`, `metadata.json`)
di `model/artifacts/`. Jika belum ada, web menolak memprediksi (tidak memalsukan hasil).

## Menjalankan Aplikasi

```powershell
cd "D:\KULIAH\Semester 5\Project Base Learning\GlucoSafe\web-flask"
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -r requirements-ml.txt
.\.venv\Scripts\python.exe app.py
```

Akses:
- Dashboard: `http://localhost:5000/`
- Health: `http://localhost:5000/api/health`

## Menjalankan Pengujian

```powershell
cd "D:\KULIAH\Semester 5\Project Base Learning\GlucoSafe\web-flask"
.\.venv\Scripts\python.exe -m pytest tests -q
```

Pengujian mencakup validasi fitur, upload CSV, inferensi batch, hybrid `user_id`,
serta endpoint API.
