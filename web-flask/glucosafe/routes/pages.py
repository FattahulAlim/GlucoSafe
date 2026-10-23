"""Halaman website Flask: Panel Pengolahan & Pembersihan Data GlucoSafe.

Panel khusus untuk:
- Unggah dataset mentah (hingga 200k+ baris)
- Preprocessing: imputasi/pembersihan missing value, eliminasi outlier, rekayasa BMI
- Menampilkan metrik data bersih vs data kotor
- Unduh Cleaned Dataset CSV untuk digunakan dalam training model skrining mobile
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

from ..data_cleaner import (
    MAX_ROWS,
    PreprocessingError,
    clean_and_preprocess_dataset,
)
from ..features import FEATURE_COLUMNS

pages_bp = Blueprint("pages", __name__)

_CLEAN_STORE: Dict[str, Dict[str, Any]] = {}


def _remove_file(data: Dict[str, Any]) -> None:
    path = data.get("result_file_path")
    if path and os.path.exists(path):
        try:
            os.remove(path)
        except OSError:
            pass


def _cleanup_store() -> None:
    ttl = current_app.config.get("RESULT_TTL_SECONDS", 1800)
    now = time.time()
    expired = [k for k, v in _CLEAN_STORE.items() if now - v.get("_created_at", 0) > ttl]
    for key in expired:
        data = _CLEAN_STORE.pop(key, None)
        if data:
            _remove_file(data)


def _store_clean_result(data: Dict[str, Any]) -> str:
    _cleanup_store()
    token = uuid.uuid4().hex
    data["_created_at"] = time.time()
    _CLEAN_STORE[token] = data
    return token


def _get_clean_result(token: str) -> Dict[str, Any]:
    ttl = current_app.config.get("RESULT_TTL_SECONDS", 1800)
    data = _CLEAN_STORE.get(token)
    if not data:
        return {}
    if time.time() - data.get("_created_at", 0) > ttl:
        _CLEAN_STORE.pop(token, None)
        _remove_file(data)
        return {}
    return data


def _result_dir() -> str:
    path = os.path.join(current_app.instance_path, "cleaned_datasets")
    os.makedirs(path, exist_ok=True)
    return path


@pages_bp.route("/")
def home():
    """Halaman Dashboard Pengolahan Data."""
    token = request.args.get("token", "")
    clean_data = _get_clean_result(token) if token else None

    return render_template(
        "home.html",
        feature_columns=FEATURE_COLUMNS,
        clean_data=clean_data,
        token=token,
        max_rows_display=f"{MAX_ROWS:,}".replace(",", "."),
    )


@pages_bp.route("/process", methods=["GET", "POST"])
def process():
    """Upload dan jalankan pembersihan/preprocessing dataset."""
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

    try:
        result = clean_and_preprocess_dataset(uploaded, output_dir=_result_dir())
        result["filename"] = filename
    except PreprocessingError as e:
        flash(str(e), "danger")
        return redirect(url_for("pages.home"))
    except Exception as e:
        current_app.logger.exception("Kesalahan saat olah dataset: %s", e)
        flash("Terjadi kesalahan teknis saat memproses dataset.", "danger")
        return redirect(url_for("pages.home"))

    token = _store_clean_result(result)
    return redirect(url_for("pages.home", token=token, _anchor="output-section"))


@pages_bp.route("/download/<token>")
def download_csv(token: str):
    """Unduh Cleaned Dataset CSV siap latih."""
    data = _get_clean_result(token)
    path = data.get("result_file_path") if data else None
    if not path or not os.path.exists(path):
        flash("Berkas unduhan sudah tidak tersedia atau kedaluwarsa.", "warning")
        return redirect(url_for("pages.home"))

    filename = data.get("filename", "dataset.csv")
    download_name = f"cleaned_{filename}"
    return send_file(
        path,
        mimetype="text/csv",
        as_attachment=True,
        download_name=download_name,
        max_age=0,
    )


@pages_bp.route("/sample.csv")
def sample_csv():
    """Unduh template CSV 15 fitur standar."""
    from ..batch_service import generate_sample_csv

    content = generate_sample_csv()
    return Response(
        content,
        mimetype="text/csv",
        headers={"Content-Disposition": 'attachment; filename="glucosafe_sample_15_features.csv"'},
    )

