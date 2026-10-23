"""Halaman website Flask: Pengolahan Dataset, Inferensi Model & Sinkronisasi DB.

Alur kerja:
1. Pengguna mengunggah dataset CSV (skala hingga 200k+ baris).
2. Model ML memproses seluruh baris secara chunking (vektorisasi numpy).
3. Hasil inferensi (pred_label, pred_score) ditulis ke berkas CSV dan
   otomatis disimpan ke database MySQL (tabel ``screening_results``).
4. Aplikasi mobile GlucoSafe dapat langsung menarik hasil via API riwayat.
"""

import os
import time
import uuid
from typing import Any, Dict

from flask import (
    Blueprint,
    Response,
    current_app,
    flash,
    redirect,
    render_template,
    request,
    send_file,
    url_for,
)
from werkzeug.utils import secure_filename

from ..batch_service import (
    MAX_BATCH_ROWS,
    BatchProcessError,
    generate_sample_csv,
    process_batch_stream,
)
from ..database import check_connection
from ..features import FEATURE_COLUMNS

pages_bp = Blueprint("pages", __name__)

_BATCH_STORE: Dict[str, Dict[str, Any]] = {}


def _get_db_config() -> Dict[str, Any]:
    return {
        "DB_HOST": current_app.config.get("DB_HOST", "localhost"),
        "DB_PORT": int(current_app.config.get("DB_PORT", 3306)),
        "DB_USER": current_app.config.get("DB_USER", "root"),
        "DB_PASSWORD": current_app.config.get("DB_PASSWORD", ""),
        "DB_NAME": current_app.config.get("DB_NAME", "glucosafe"),
    }


def _remove_batch_file(data: Dict[str, Any]) -> None:
    path = data.get("result_file_path")
    if path and os.path.exists(path):
        try:
            os.remove(path)
        except OSError:
            pass


def _cleanup_batches() -> None:
    ttl = current_app.config.get("RESULT_TTL_SECONDS", 1800)
    now = time.time()
    expired = [k for k, v in _BATCH_STORE.items() if now - v.get("_created_at", 0) > ttl]
    for key in expired:
        data = _BATCH_STORE.pop(key, None)
        if data:
            _remove_batch_file(data)


def _store_batch(data: Dict[str, Any]) -> str:
    _cleanup_batches()
    token = uuid.uuid4().hex
    data["_created_at"] = time.time()
    _BATCH_STORE[token] = data
    return token


def _get_batch(token: str) -> Dict[str, Any]:
    ttl = current_app.config.get("RESULT_TTL_SECONDS", 1800)
    data = _BATCH_STORE.get(token)
    if not data:
        return {}
    if time.time() - data.get("_created_at", 0) > ttl:
        _BATCH_STORE.pop(token, None)
        _remove_batch_file(data)
        return {}
    return data


def _result_dir() -> str:
    path = os.path.join(current_app.instance_path, "batch_results")
    os.makedirs(path, exist_ok=True)
    return path


@pages_bp.route("/")
def home():
    """Halaman Dashboard Olah Dataset & Sinkronisasi Mobile."""
    model_service = current_app.extensions["model_service"]
    token = request.args.get("token", "")
    batch_data = _get_batch(token) if token else None

    db_config = _get_db_config()
    db_error = check_connection(db_config)
    db_connected = db_error is None

    return render_template(
        "home.html",
        feature_columns=FEATURE_COLUMNS,
        status=model_service.status(),
        batch=batch_data,
        token=token,
        max_rows_display=f"{MAX_BATCH_ROWS:,}".replace(",", "."),
        db_connected=db_connected,
        db_error=db_error,
        db_name=db_config["DB_NAME"],
        screening_user_id=int(current_app.config.get("SCREENING_USER_ID", 1)),
    )


@pages_bp.route("/process", methods=["GET", "POST"])
def process():
    """Upload berkas CSV, jalankan model ML batch, dan sinkronkan ke DB."""
    if request.method == "GET":
        return redirect(url_for("pages.home"))

    uploaded = request.files.get("csv_file")
    if not uploaded or not uploaded.filename:
        flash("Pilih berkas CSV dataset terlebih dahulu.", "warning")
        return redirect(url_for("pages.home"))

    filename = secure_filename(uploaded.filename)
    if not filename.lower().endswith(".csv"):
        flash("Berkas harus berekstensi .csv.", "danger")
        return redirect(url_for("pages.home"))

    # Opsi penyimpanan ke DB (otomatis pakai SCREENING_USER_ID jika baris CSV tidak punya user_id)
    save_to_db = request.form.get("save_to_db") in ("1", "true", "on")
    default_user_id = int(current_app.config.get("SCREENING_USER_ID", 1))

    db_config = _get_db_config() if save_to_db else None

    try:
        model_service = current_app.extensions["model_service"]
        result = process_batch_stream(
            uploaded,
            model_service=model_service,
            output_dir=_result_dir(),
            db_config=db_config,
            default_user_id=default_user_id,
        )
        result["filename"] = filename
    except BatchProcessError as e:
        flash(str(e), "danger")
        return redirect(url_for("pages.home"))
    except Exception as e:
        current_app.logger.exception("Kesalahan saat olah dataset: %s", e)
        flash("Terjadi kesalahan teknis saat memproses dataset.", "danger")
        return redirect(url_for("pages.home"))

    token = _store_batch(result)
    return redirect(url_for("pages.home", token=token, _anchor="output-section"))


@pages_bp.route("/download/<token>")
def download_csv(token: str):
    """Unduh CSV hasil inferensi model secara streaming dari disk."""
    data = _get_batch(token)
    path = data.get("result_file_path") if data else None
    if not path or not os.path.exists(path):
        flash("Berkas unduhan sudah tidak tersedia atau kedaluwarsa.", "warning")
        return redirect(url_for("pages.home"))

    filename = data.get("filename", "dataset.csv")
    download_name = f"processed_{filename}"
    return send_file(
        path,
        mimetype="text/csv",
        as_attachment=True,
        download_name=download_name,
        max_age=0,
    )


@pages_bp.route("/sample.csv")
def sample_csv():
    """Unduh contoh berkas CSV 15 fitur dengan kolom user_id."""
    content = generate_sample_csv()
    return Response(
        content,
        mimetype="text/csv",
        headers={"Content-Disposition": 'attachment; filename="glucosafe_dataset_sample.csv"'},
    )
