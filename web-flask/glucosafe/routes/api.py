"""Blueprint API JSON untuk GlucoSafe.

Sesuai PRD_GlucoSafe.md v1.3:
- GET  /api/health  -> Mengembalikan status layanan, model_ready, dan versi model bila tersedia.
- POST /api/predict -> Menerima input JSON (features), validasi, preprocessing, model ML,
                      dan mengembalikan hasil JSON.
                      200 berhasil, 400 input tidak valid, 415 format bukan JSON,
                      503 model belum siap, 500 kegagalan internal.
"""

import logging
from flask import Blueprint, current_app, jsonify, request

from ..features import FEATURE_COLUMNS, validate_features

api_bp = Blueprint("api", __name__)
logger = logging.getLogger(__name__)


@api_bp.route("/health", methods=["GET"])
def health():
    """Endpoint pemeriksaan kesehatan layanan dan kesiapan model."""
    model_service = current_app.extensions["model_service"]
    status_info = model_service.status()

    return jsonify(
        success=True,
        service="GlucoSafe ML API",
        status="healthy",
        model_ready=status_info["model_ready"],
        model_version=status_info["version"],
        algorithm=status_info["algorithm"],
        feature_count=status_info["feature_count"],
        expected_features=FEATURE_COLUMNS,
    ), 200


@api_bp.route("/predict", methods=["POST"])
def predict():
    """Endpoint inferensi prediksi diabetes."""
    # PRD v1.3: status 415 jika format bukan JSON
    if not request.is_json:
        return jsonify(
            success=False,
            error={
                "code": "UNSUPPORTED_MEDIA_TYPE",
                "message": "Format permintaan harus application/json.",
            },
        ), 415

    payload = request.get_json(silent=True)
    if payload is None or not isinstance(payload, dict):
        return jsonify(
            success=False,
            error={
                "code": "INVALID_JSON",
                "message": "Body JSON tidak valid atau kosong.",
            },
        ), 400

    # PRD v1.3: Request prediksi menggunakan objek features
    if "features" not in payload:
        return jsonify(
            success=False,
            error={
                "code": "MISSING_FEATURES",
                "message": "Permintaan harus menyertakan objek 'features'.",
            },
        ), 400

    raw_features = payload["features"]
    cleaned_features, field_errors = validate_features(raw_features)
    if field_errors:
        return jsonify(
            success=False,
            error={
                "code": "VALIDATION_ERROR",
                "message": "Validasi input fitur gagal.",
                "fields": field_errors,
            },
        ), 400

    model_service = current_app.extensions["model_service"]
    if not model_service.is_ready:
        return jsonify(
            success=False,
            error={
                "code": "MODEL_NOT_READY",
                "message": "Model belum tersedia. Prediksi belum dapat dijalankan.",
            },
            model_ready=False,
        ), 503

    try:
        pred_result = model_service.predict(cleaned_features)
    except Exception:
        logger.exception("Kesalahan internal saat menjalankan model ML.")
        return jsonify(
            success=False,
            error={
                "code": "INTERNAL_ERROR",
                "message": "Terjadi kesalahan internal saat memproses prediksi.",
            },
        ), 500

    # Format respons PRD v1.3: prediction, model_version, score (opsional)
    response_body = {
        "success": True,
        "prediction": pred_result.risk_label,
        "model_version": pred_result.model_version,
    }

    if pred_result.risk_percent is not None:
        response_body["score"] = pred_result.risk_percent

    return jsonify(response_body), 200
