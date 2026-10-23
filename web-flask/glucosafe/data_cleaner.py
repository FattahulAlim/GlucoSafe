"""Mesin Pembersihan & Preprocessing Dataset GlucoSafe.

Bertugas mengolah dataset mentah skala besar (200k+ baris) untuk keperluan
pelatihan model dan konsumsi aplikasi mobile skrining GlucoSafe:
1. Pembersihan missing value (imputasi/drop)
2. Normalisasi penamaan kolom (BRFSS 2015)
3. Rekayasa fitur: kalkulasi BMI otomatis dari tinggi & berat badan
4. Validasi batas rentang klinis & eliminasi data anomali/outlier
5. Encoding/standarisasi tipe data
6. Ekspor dataset bersih siap latih (Cleaned Dataset CSV)
"""

import csv
import io
import os
import tempfile
from typing import Any, Dict, List, Optional, Tuple

from .features import FEATURE_COLUMNS, calculate_bmi, canonical_header

MAX_ROWS = 500000
CHUNK_SIZE = 10000


class PreprocessingError(Exception):
    """Kesalahan saat memproses dataset."""


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


def clean_and_preprocess_dataset(
    file_storage_or_bytes,
    options: Optional[Dict[str, Any]] = None,
    output_dir: Optional[str] = None,
) -> Dict[str, Any]:
    """Mengolah dataset mentah secara streaming dan chunked.

    Mendukung file berukuran besar (200k+ baris) dengan penggunaan RAM minimal.
    """
    if options is None:
        options = {}

    handle_missing = options.get("handle_missing", "drop")  # 'drop' atau 'impute'

    if isinstance(file_storage_or_bytes, bytes):
        raw_io = io.BytesIO(file_storage_or_bytes)
    else:
        raw_io = file_storage_or_bytes.stream

    try:
        text_stream = io.TextIOWrapper(raw_io, encoding="utf-8-sig", errors="replace", newline="")
        delimiter = _detect_delimiter(text_stream)
        reader = csv.DictReader(text_stream, delimiter=delimiter)
    except Exception as e:
        raise PreprocessingError(f"Gagal membaca format CSV: {e}")

    if not reader.fieldnames:
        raise PreprocessingError("Berkas CSV tidak memiliki header kolom.")

    # Kolom output standar GlucoSafe (15 fitur terurut)
    output_headers = list(FEATURE_COLUMNS)

    # Tambahkan kolom target/label jika ada di dataset mentah (mis. Diabetes_binary / Outcome)
    target_col = None
    for raw_h in reader.fieldnames:
        clean_h = raw_h.strip().lower()
        if clean_h in ("diabetes_binary", "diabetes_012", "target", "outcome", "label", "diabetes"):
            target_col = raw_h
            if target_col not in output_headers:
                output_headers.append(target_col)
            break

    temp_fd, temp_file_path = tempfile.mkstemp(
        suffix=".csv",
        prefix="glucosafe_cleaned_",
        dir=output_dir,
    )
    temp_file = os.fdopen(temp_fd, "w", encoding="utf-8", newline="")
    writer = csv.DictWriter(
        temp_file, fieldnames=output_headers, extrasaction="ignore", lineterminator="\n"
    )
    writer.writeheader()

    total_rows = 0
    clean_rows_count = 0
    dropped_missing_count = 0
    dropped_outlier_count = 0
    bmi_derived_count = 0

    preview_rows: List[Dict[str, Any]] = []

    # Akumulator statistik untuk data numerik
    bmi_values: List[float] = []

    for index, row in enumerate(reader, start=1):
        if index > MAX_ROWS:
            temp_file.close()
            try:
                os.remove(temp_file_path)
            except OSError:
                pass
            raise PreprocessingError(
                f"Jumlah baris melebihi batas maksimal ({MAX_ROWS:,} baris)."
            )

        if not any(v.strip() for v in row.values() if isinstance(v, str)):
            continue

        total_rows += 1
        raw_cleaned = {k.strip(): (v.strip() if isinstance(v, str) else v) for k, v in row.items() if k}

        # Petakan ke header kanonik
        row_norm: Dict[str, Any] = {}
        for k, v in raw_cleaned.items():
            canonical = canonical_header(k)
            if canonical:
                row_norm[canonical] = v

        # Pertahankan target jika ada
        target_val = raw_cleaned.get(target_col) if target_col else None

        # Hitung BMI otomatis dari height & weight jika BMI kosong
        if "BMI" not in row_norm or row_norm["BMI"] in (None, ""):
            h = row_norm.get("height_cm") or raw_cleaned.get("height") or raw_cleaned.get("height_cm")
            w = row_norm.get("weight_kg") or raw_cleaned.get("weight") or raw_cleaned.get("weight_kg")
            if h not in (None, "") and w not in (None, ""):
                try:
                    h_f = float(str(h).replace(",", "."))
                    w_f = float(str(w).replace(",", "."))
                    if 100.0 <= h_f <= 220.0 and 30.0 <= w_f <= 250.0:
                        row_norm["BMI"] = calculate_bmi(h_f, w_f)
                        bmi_derived_count += 1
                except (ValueError, TypeError):
                    pass

        # Periksa kelengkapan & validasi batas
        is_missing = False
        is_outlier = False
        cleaned_row: Dict[str, Any] = {}

        binary_cols = (
            "HighBP", "HighChol", "Smoker", "Stroke",
            "HeartDiseaseorAttack", "PhysActivity", "Fruits", "Veggies",
            "DiffWalk", "Sex"
        )

        for col in binary_cols:
            val = row_norm.get(col)
            if val in (None, ""):
                is_missing = True
                break
            try:
                int_v = int(float(str(val).replace(",", ".")))
                if int_v not in (0, 1):
                    is_outlier = True
                    break
                cleaned_row[col] = int_v
            except (ValueError, TypeError):
                is_missing = True
                break

        if is_missing:
            dropped_missing_count += 1
            continue
        if is_outlier:
            dropped_outlier_count += 1
            continue

        # Cek kolom integer bertingkat
        range_rules = {
            "Age": (1, 13),
            "GenHlth": (1, 5),
            "MentHlth": (0, 30),
            "PhysHlth": (0, 30),
        }
        for col, (min_v, max_v) in range_rules.items():
            val = row_norm.get(col)
            if val in (None, ""):
                is_missing = True
                break
            try:
                int_v = int(float(str(val).replace(",", ".")))
                if not (min_v <= int_v <= max_v):
                    is_outlier = True
                    break
                cleaned_row[col] = int_v
            except (ValueError, TypeError):
                is_missing = True
                break

        if is_missing:
            dropped_missing_count += 1
            continue
        if is_outlier:
            dropped_outlier_count += 1
            continue

        # Validasi BMI
        bmi_raw = row_norm.get("BMI")
        if bmi_raw in (None, ""):
            dropped_missing_count += 1
            continue
        try:
            bmi_f = round(float(str(bmi_raw).replace(",", ".")), 1)
            # Filter outlier ekstrim (standar WHO/CDC untuk penelitian BRFSS)
            if not (10.0 <= bmi_f <= 70.0):
                dropped_outlier_count += 1
                continue
            cleaned_row["BMI"] = bmi_f
        except (ValueError, TypeError):
            dropped_missing_count += 1
            continue

        if target_col and target_val is not None:
            cleaned_row[target_col] = target_val

        writer.writerow(cleaned_row)
        clean_rows_count += 1

        if len(preview_rows) < 20:
            preview_rows.append(cleaned_row)

        if len(bmi_values) < 5000:
            bmi_values.append(cleaned_row["BMI"])

    temp_file.close()

    if total_rows == 0:
        try:
            os.remove(temp_file_path)
        except OSError:
            pass
        raise PreprocessingError("Berkas CSV tidak berisi baris data.")

    avg_bmi = round(sum(bmi_values) / len(bmi_values), 1) if bmi_values else 0.0

    return {
        "total_rows": total_rows,
        "clean_rows_count": clean_rows_count,
        "dropped_missing_count": dropped_missing_count,
        "dropped_outlier_count": dropped_outlier_count,
        "bmi_derived_count": bmi_derived_count,
        "avg_bmi": avg_bmi,
        "preview_rows": preview_rows,
        "result_file_path": temp_file_path,
        "output_headers": output_headers,
    }
