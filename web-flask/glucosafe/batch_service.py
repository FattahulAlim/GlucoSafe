"""Pengolah dataset CSV: validasi massal, inferensi batch, dan ekspor.

Mendukung dataset besar (200k+ baris) dengan teknik:
1. Streaming pembacaan baris demi baris (bukan simpan semua di memory)
2. Inferensi matriks vektorisasi NumPy per chunk (5.000 - 10.000 baris)
3. Penulisan hasil langsung ke file sementara (temp file) di disk
4. Pratinjau di layar dibatasi (20-50 baris) agar browser tetap ringan
"""

import csv
import io
import os
import tempfile
from typing import Any, Dict, Generator, List, Optional, Tuple

from .features import FEATURE_COLUMNS, validate_features
from .model_service import ModelService

# Maksimal baris yang diizinkan (dinaikkan hingga 500.000 baris)
MAX_BATCH_ROWS = 500000
CHUNK_SIZE = 10000


class BatchProcessError(Exception):
    """Kesalahan saat memproses batch CSV."""


def _detect_delimiter(file_stream) -> str:
    pos = file_stream.tell()
    sample = file_stream.read(4096)
    file_stream.seek(pos)
    try:
        sniffer = csv.Sniffer()
        dialect = sniffer.sniff(sample, delimiters=";,|\t,")
        return dialect.delimiter
    except Exception:
        return ","


def process_batch_stream(
    file_storage_or_bytes,
    model_service: ModelService,
    output_dir: Optional[str] = None,
) -> Dict[str, Any]:
    """Mengolah CSV skala besar secara streaming dan chunked inference.

    Hasil CSV lengkap ditulis langsung ke file disk sementara, mengembalikan
    path berkas untuk unduhan tanpa membebani RAM server.
    """
    if isinstance(file_storage_or_bytes, bytes):
        raw_io = io.BytesIO(file_storage_or_bytes)
    else:
        raw_io = file_storage_or_bytes.stream

    # Bungkus TextIOWrapper dengan decoding UTF-8 / Latin-1 yang tahan BOM
    try:
        text_stream = io.TextIOWrapper(raw_io, encoding="utf-8-sig", errors="replace", newline="")
        delimiter = _detect_delimiter(text_stream)
        reader = csv.DictReader(text_stream, delimiter=delimiter)
    except Exception as e:
        raise BatchProcessError(f"Gagal membaca format CSV: {e}")

    if not reader.fieldnames:
        raise BatchProcessError("Berkas CSV tidak memiliki header kolom.")

    headers = [h.strip() for h in reader.fieldnames if h]

    # Siapkan file output sementara di disk
    temp_fd, temp_file_path = tempfile.mkstemp(
        suffix=".csv",
        prefix="glucosafe_out_",
        dir=output_dir,
    )
    temp_file = os.fdopen(temp_fd, "w", encoding="utf-8", newline="")

    output_headers = list(headers)
    for col in FEATURE_COLUMNS + ["pred_label", "pred_score", "model_version"]:
        if col not in output_headers:
            output_headers.append(col)

    writer = csv.DictWriter(
        temp_file, fieldnames=output_headers, extrasaction="ignore", lineterminator="\n"
    )
    writer.writeheader()

    total_rows = 0
    valid_count = 0
    invalid_count = 0
    label_counts: Dict[str, int] = {}
    row_errors: List[Dict[str, Any]] = []
    preview_rows: List[Dict[str, Any]] = []

    model_ready = model_service.is_ready

    # Buffer chunk untuk inferensi massal
    chunk_raw_records: List[Dict[str, Any]] = []
    chunk_features_matrix: List[List[Any]] = []

    def flush_chunk():
        nonlocal valid_count, chunk_raw_records, chunk_features_matrix
        if not chunk_raw_records:
            return

        if model_ready:
            # Gunakan predict_matrix (vektorisasi numpy cepat)
            batch_preds = model_service.predict_matrix(chunk_features_matrix)
            for i, record in enumerate(chunk_raw_records):
                pred = batch_preds[i]
                lbl = pred["label"]
                score_str = f"{pred['score']:.2f}" if pred["score"] is not None else ""
                ver = pred["version"]

                record["pred_label"] = lbl
                record["pred_score"] = score_str
                record["model_version"] = ver

                label_counts[lbl] = label_counts.get(lbl, 0) + 1
                writer.writerow(record)
                if len(preview_rows) < 20:
                    preview_rows.append(record)
        else:
            for record in chunk_raw_records:
                record["pred_label"] = "MODEL_BELUM_TERSEDIA"
                record["pred_score"] = ""
                record["model_version"] = "-"
                writer.writerow(record)
                if len(preview_rows) < 20:
                    preview_rows.append(record)

        valid_count += len(chunk_raw_records)
        chunk_raw_records = []
        chunk_features_matrix = []

    for index, row in enumerate(reader, start=1):
        if index > MAX_BATCH_ROWS:
            temp_file.close()
            try:
                os.remove(temp_file_path)
            except OSError:
                pass
            raise BatchProcessError(
                f"Jumlah baris melebihi batas maksimal sistem ({MAX_BATCH_ROWS:,} baris)."
            )

        # Abaikan jika baris benar-benar kosong
        if not any(v.strip() for v in row.values() if isinstance(v, str)):
            continue

        total_rows += 1
        cleaned_row = {k.strip(): (v.strip() if isinstance(v, str) else v) for k, v in row.items() if k}

        cleaned_features, errors = validate_features(cleaned_row)
        if errors:
            invalid_count += 1
            if len(row_errors) < 50:
                row_errors.append(
                    {
                        "row_number": index,
                        "errors": errors,
                        "raw": cleaned_row,
                    }
                )
            # Tulis baris gagal dengan kolom prediksi keterangan error
            row_dict = dict(cleaned_row)
            row_dict["pred_label"] = "DATA_TIDAK_VALID"
            row_dict["pred_score"] = ""
            row_dict["model_version"] = "-"
            writer.writerow(row_dict)
            if len(preview_rows) < 20:
                preview_rows.append(row_dict)
        else:
            row_dict = dict(cleaned_row)
            for col in FEATURE_COLUMNS:
                row_dict[col] = cleaned_features[col]

            chunk_raw_records.append(row_dict)
            chunk_features_matrix.append([cleaned_features[col] for col in FEATURE_COLUMNS])

            if len(chunk_raw_records) >= CHUNK_SIZE:
                flush_chunk()

    # Flush sisa baris di chunk terakhir
    flush_chunk()
    temp_file.close()

    if total_rows == 0:
        try:
            os.remove(temp_file_path)
        except OSError:
            pass
        raise BatchProcessError("Berkas CSV tidak berisi baris data.")

    return {
        "total_rows": total_rows,
        "valid_count": valid_count,
        "invalid_count": invalid_count,
        "model_ready": model_ready,
        "model_version": model_service.version if model_ready else None,
        "label_counts": label_counts,
        "row_errors": row_errors,
        "preview_rows": preview_rows,
        "result_file_path": temp_file_path,
    }


# Kompatibilitas fungsi lama
def process_batch(raw_bytes: bytes, model_service: ModelService) -> Dict[str, Any]:
    res = process_batch_stream(raw_bytes, model_service)
    # Baca file hasil ke memori untuk kemudahan fungsi pembantu jika dipanggil
    if "result_file_path" in res and os.path.exists(res["result_file_path"]):
        with open(res["result_file_path"], "r", encoding="utf-8") as f:
            res["csv_text"] = f.read()
    return res


def generate_sample_csv() -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=FEATURE_COLUMNS, lineterminator="\n")
    writer.writeheader()
    samples = [
        {
            "HighBP": 1,
            "HighChol": 1,
            "BMI": 28.5,
            "Smoker": 0,
            "Stroke": 0,
            "HeartDiseaseorAttack": 0,
            "PhysActivity": 0,
            "Fruits": 1,
            "Veggies": 1,
            "GenHlth": 3,
            "MentHlth": 5,
            "PhysHlth": 2,
            "DiffWalk": 0,
            "Sex": 1,
            "Age": 8,
        },
        {
            "HighBP": 0,
            "HighChol": 0,
            "BMI": 22.1,
            "Smoker": 0,
            "Stroke": 0,
            "HeartDiseaseorAttack": 0,
            "PhysActivity": 1,
            "Fruits": 1,
            "Veggies": 1,
            "GenHlth": 1,
            "MentHlth": 0,
            "PhysHlth": 0,
            "DiffWalk": 0,
            "Sex": 0,
            "Age": 4,
        },
        {
            "HighBP": 1,
            "HighChol": 1,
            "BMI": 33.4,
            "Smoker": 1,
            "Stroke": 0,
            "HeartDiseaseorAttack": 1,
            "PhysActivity": 0,
            "Fruits": 0,
            "Veggies": 1,
            "GenHlth": 4,
            "MentHlth": 10,
            "PhysHlth": 14,
            "DiffWalk": 1,
            "Sex": 1,
            "Age": 10,
        },
    ]
    for row in samples:
        writer.writerow(row)
    return output.getvalue()
