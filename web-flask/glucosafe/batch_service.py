"""Pengolah dataset CSV: inferensi batch, ekspor CSV, dan simpan ke Database.

Alur:
1. Web Flask menerima unggahan berkas CSV (skala 200k+ baris).
2. Inferensi model dijalankan secara batch/chunk (pred_label & pred_score).
3. Hasil prediksi dapat disimpan ke database MySQL (tabel ``screening_results``)
   sehingga aplikasi mobile dapat langsung menariknya via endpoint riwayat skrining.
4. Mendukung penentuan ``user_id`` secara hybrid:
   - Ambil dari kolom CSV (jika tersedia per baris)
   - Fallback ke ``default_user_id`` yang dimasukkan dari form web jika kolom kosong.
"""

import csv
import io
import logging
import os
import tempfile
from typing import Any, Dict, List, Optional

from .database import DatabaseError, insert_screening_results
from .features import FEATURE_COLUMNS, normalize_row, validate_features
from .model_service import ModelService

logger = logging.getLogger(__name__)

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


def _extract_user_id(record: Dict[str, Any], default_user_id: Optional[int]) -> Optional[int]:
    """Menentukan user_id hasil olah data.

    Mode operasional saat ini: seluruh hasil dikaitkan ke satu user tetap
    (``SCREENING_USER_ID``, default 1) agar dapat langsung ditarik aplikasi mobile.
    Jika ``default_user_id`` tidak diisi, kolom ``user_id`` pada CSV dipakai.
    """
    if default_user_id is not None:
        return default_user_id

    for key in ("user_id", "userid", "user_Id", "User_ID", "UserId", "id_user"):
        if key in record and record[key] not in (None, ""):
            try:
                val = int(float(str(record[key]).strip()))
                if val > 0:
                    return val
            except (ValueError, TypeError):
                pass
    return None


def process_batch_stream(
    file_storage_or_bytes,
    model_service: ModelService,
    output_dir: Optional[str] = None,
    db_config: Optional[Dict[str, Any]] = None,
    default_user_id: Optional[int] = None,
) -> Dict[str, Any]:
    """Mengolah CSV secara streaming, chunked inference, dan opsi simpan DB."""
    if isinstance(file_storage_or_bytes, bytes):
        raw_io = io.BytesIO(file_storage_or_bytes)
    else:
        raw_io = file_storage_or_bytes.stream

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
    for col in FEATURE_COLUMNS + ["user_id", "pred_label", "pred_score", "model_version"]:
        if col not in output_headers:
            output_headers.append(col)

    writer = csv.DictWriter(
        temp_file, fieldnames=output_headers, extrasaction="ignore", lineterminator="\n"
    )
    writer.writeheader()

    total_rows = 0
    valid_count = 0
    invalid_count = 0
    saved_to_db_count = 0
    db_error_message: Optional[str] = None
    label_counts: Dict[str, int] = {}
    row_errors: List[Dict[str, Any]] = []
    preview_rows: List[Dict[str, Any]] = []

    model_ready = model_service.is_ready

    chunk_raw_records: List[Dict[str, Any]] = []
    chunk_features_matrix: List[List[Any]] = []

    def flush_chunk():
        nonlocal valid_count, saved_to_db_count, db_error_message
        nonlocal chunk_raw_records, chunk_features_matrix
        if not chunk_raw_records:
            return

        db_rows: List[Dict[str, Any]] = []

        if model_ready:
            batch_preds = model_service.predict_matrix(chunk_features_matrix)
            for i, record in enumerate(chunk_raw_records):
                pred = batch_preds[i]
                lbl = pred["label"]
                score_val = pred["score"]
                score_str = f"{score_val:.2f}" if score_val is not None else ""
                ver = pred["version"]

                record["pred_label"] = lbl
                record["pred_score"] = score_str
                record["model_version"] = ver

                target_user = _extract_user_id(record, default_user_id)
                record["user_id"] = target_user if target_user is not None else ""

                label_counts[lbl] = label_counts.get(lbl, 0) + 1
                writer.writerow(record)
                if len(preview_rows) < 20:
                    preview_rows.append(record)

                if db_config and target_user is not None:
                    db_label = lbl if lbl in ("Rendah", "Sedang", "Tinggi") else "Sedang"
                    db_score = float(score_val) if score_val is not None else 0.0
                    height = float(record.get("height_cm") or 165.0)
                    bmi = float(record.get("BMI") or 22.0)
                    weight = float(record.get("weight_kg") or round(bmi * ((height / 100.0) ** 2), 1))

                    db_rows.append(
                        {
                            "user_id": target_user,
                            "risk_percent": db_score,
                            "risk_label": db_label,
                            "sex": int(record["Sex"]),
                            "age": int(record["Age"]),
                            "height_cm": height,
                            "weight_kg": weight,
                            "bmi": bmi,
                            "high_bp": int(record["HighBP"]),
                            "high_chol": int(record["HighChol"]),
                            "stroke": int(record["Stroke"]),
                            "heart_disease": int(record["HeartDiseaseorAttack"]),
                            "diff_walk": int(record["DiffWalk"]),
                            "smoker": int(record["Smoker"]),
                            "phys_activity": int(record["PhysActivity"]),
                            "fruits": int(record["Fruits"]),
                            "veggies": int(record["Veggies"]),
                            "gen_hlth": int(record["GenHlth"]),
                            "ment_hlth": int(record["MentHlth"]),
                            "phys_hlth": int(record["PhysHlth"]),
                        }
                    )
        else:
            for record in chunk_raw_records:
                record["pred_label"] = "MODEL_BELUM_TERSEDIA"
                record["pred_score"] = ""
                record["model_version"] = "-"
                target_user = _extract_user_id(record, default_user_id)
                record["user_id"] = target_user if target_user is not None else ""
                writer.writerow(record)
                if len(preview_rows) < 20:
                    preview_rows.append(record)

        if db_config and db_rows:
            try:
                inserted = insert_screening_results(db_config, db_rows)
                saved_to_db_count += inserted
            except DatabaseError as exc:
                if db_error_message is None:
                    db_error_message = str(exc)
                logger.warning("Gagal menyimpan chunk ke DB: %s", exc)

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

        if not any(v.strip() for v in row.values() if isinstance(v, str)):
            continue

        total_rows += 1
        cleaned_row = {k.strip(): (v.strip() if isinstance(v, str) else v) for k, v in row.items() if k}
        normalized_row = normalize_row(cleaned_row)

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
            row_dict = dict(cleaned_row)
            row_dict["pred_label"] = "DATA_TIDAK_VALID"
            row_dict["pred_score"] = ""
            row_dict["model_version"] = "-"
            row_dict["user_id"] = _extract_user_id(cleaned_row, default_user_id) or ""
            writer.writerow(row_dict)
            if len(preview_rows) < 20:
                preview_rows.append(row_dict)
        else:
            row_dict = dict(cleaned_row)
            for col in FEATURE_COLUMNS:
                row_dict[col] = cleaned_features[col]
            if "height_cm" in normalized_row:
                row_dict["height_cm"] = normalized_row["height_cm"]
            if "weight_kg" in normalized_row:
                row_dict["weight_kg"] = normalized_row["weight_kg"]

            chunk_raw_records.append(row_dict)
            chunk_features_matrix.append([cleaned_features[col] for col in FEATURE_COLUMNS])

            if len(chunk_raw_records) >= CHUNK_SIZE:
                flush_chunk()

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
        "saved_to_db_count": saved_to_db_count,
        "db_error": db_error_message,
    }


def process_batch(raw_bytes: bytes, model_service: ModelService) -> Dict[str, Any]:
    """Kompatibilitas pembantu unit test."""
    res = process_batch_stream(raw_bytes, model_service)
    if "result_file_path" in res and os.path.exists(res["result_file_path"]):
        with open(res["result_file_path"], "r", encoding="utf-8") as f:
            res["csv_text"] = f.read()
    return res


def generate_sample_csv() -> str:
    """Menghasilkan sample CSV lengkap termasuk kolom user_id."""
    output = io.StringIO()
    cols = ["user_id"] + FEATURE_COLUMNS
    writer = csv.DictWriter(output, fieldnames=cols, lineterminator="\n")
    writer.writeheader()
    samples = [
        {
            "user_id": 1,
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
            "user_id": 1,
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
            "user_id": 2,
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
