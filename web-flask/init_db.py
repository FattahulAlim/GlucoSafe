"""Script inisialisasi skema database MySQL GlucoSafe."""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import pymysql

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent
SQL_PATH = BASE_DIR.parent / "backend" / "database" / "glucosafe.sql"

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", 3306))
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "glucosafe")


def init_database():
    print(f"Menghubungkan ke MySQL di {DB_HOST}:{DB_PORT} (user: {DB_USER})...")
    conn = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        charset="utf8mb4",
        autocommit=True,
    )

    if not SQL_PATH.is_file():
        print(f"Error: Berkas SQL tidak ditemukan di {SQL_PATH}")
        sys.exit(1)

    print(f"Membaca skema dari {SQL_PATH}...")
    with open(SQL_PATH, "r", encoding="utf-8") as f:
        sql_content = f.read()

    # Eksekusi per query
    with conn.cursor() as cur:
        # Pisah statement berdasarkan delimiter titik koma
        statements = [stmt.strip() for stmt in sql_content.split(";") if stmt.strip()]
        for stmt in statements:
            # Lewati komentar murni
            lines = [l for l in stmt.splitlines() if not l.strip().startswith("--")]
            cleaned_stmt = "\n".join(lines).strip()
            if cleaned_stmt:
                try:
                    cur.execute(cleaned_stmt)
                except Exception as e:
                    print(f"Peringatan query: {e}")

    conn.close()

    # Verifikasi tabel
    conn_db = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="utf8mb4",
    )
    with conn_db.cursor() as cur:
        cur.execute("SHOW TABLES;")
        tables = [row[0] for row in cur.fetchall()]
        print(f"Database '{DB_NAME}' berhasil diinisialisasi!")
        print(f"Tabel yang tersedia: {', '.join(tables)}")

        for table in tables:
            cur.execute(f"SELECT COUNT(*) FROM `{table}`;")
            count = cur.fetchone()[0]
            print(f" - {table}: {count} baris")

    conn_db.close()


if __name__ == "__main__":
    init_database()
