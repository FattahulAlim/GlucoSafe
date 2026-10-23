"""Koneksi database MySQL GlucoSafe.

Web Flask hanya bertugas menyimpan hasil olah data + hasil prediksi model
ke tabel ``screening_results``. Aplikasi mobile menarik riwayat tersebut
lewat backend Node.js (``GET /api/screenings``).

Catatan:
- Jika PyMySQL belum terpasang atau kredensial salah, aplikasi tetap bisa
  mengolah CSV dan mengunduh hasil, hanya penyimpanan DB yang dilewati
  (dengan pesan peringatan yang jelas, bukan data palsu).
"""

import logging
from typing import Any, Dict, Iterable, List, Optional

logger = logging.getLogger(__name__)

DB_COLUMNS = [
    "user_id",
    "risk_percent",
    "risk_label",
    "sex",
    "age",
    "height_cm",
    "weight_kg",
    "bmi",
    "high_bp",
    "high_chol",
    "stroke",
    "heart_disease",
    "diff_walk",
    "smoker",
    "phys_activity",
    "fruits",
    "veggies",
    "gen_hlth",
    "ment_hlth",
    "phys_hlth",
]


class DatabaseError(Exception):
    """Kegagalan koneksi atau penyimpanan ke database."""


def _connect(config: Dict[str, Any]):
    try:
        import pymysql  # type: ignore
    except ImportError as exc:  # pragma: no cover - depends on environment
        raise DatabaseError(
            "Driver database PyMySQL belum terpasang. Jalankan: pip install -r requirements.txt"
        ) from exc

    try:
        return pymysql.connect(
            host=config.get("DB_HOST", "localhost"),
            port=int(config.get("DB_PORT", 3306)),
            user=config.get("DB_USER", "root"),
            password=config.get("DB_PASSWORD", ""),
            database=config.get("DB_NAME", "glucosafe"),
            charset="utf8mb4",
            connect_timeout=5,
            autocommit=False,
            cursorclass=pymysql.cursors.DictCursor,
        )
    except Exception as exc:  # pragma: no cover - depends on environment
        raise DatabaseError(f"Gagal terhubung ke database MySQL: {exc}") from exc


def insert_screening_results(
    config: Dict[str, Any],
    rows: Iterable[Dict[str, Any]],
) -> int:
    """Menyimpan sekumpulan hasil prediksi ke tabel ``screening_results``.

    Mengembalikan jumlah baris yang berhasil dimasukkan.
    """
    rows = [row for row in rows if row.get("user_id") is not None]
    if not rows:
        return 0

    placeholders = ", ".join(["%s"] * len(DB_COLUMNS))
    columns_sql = ", ".join(DB_COLUMNS)
    sql = f"INSERT INTO screening_results ({columns_sql}) VALUES ({placeholders})"

    values: List[List[Any]] = []
    for row in rows:
        values.append([row.get(col) for col in DB_COLUMNS])

    connection = _connect(config)
    try:
        with connection.cursor() as cursor:
            cursor.executemany(sql, values)
        connection.commit()
        return len(values)
    except Exception as exc:  # pragma: no cover - depends on environment
        connection.rollback()
        raise DatabaseError(f"Gagal menyimpan hasil ke database: {exc}") from exc
    finally:
        connection.close()


def check_connection(config: Dict[str, Any]) -> Optional[str]:
    """Mengembalikan pesan error jika DB tidak dapat diakses, atau None."""
    try:
        connection = _connect(config)
        connection.close()
        return None
    except DatabaseError as exc:
        return str(exc)
