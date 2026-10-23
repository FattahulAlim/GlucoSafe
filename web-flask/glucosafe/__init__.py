"""GlucoSafe web application package.

Sesuai PRD_GlucoSafe.md v1.3 dan design.md:
- Satu halaman website di GET /
- API JSON di /api/health dan /api/predict
- Validasi ketat, preprocessing konsisten, dan penanganan kegagalan aman
"""

import logging
import os
from pathlib import Path

from flask import Flask, jsonify, render_template, request

from .model_service import ModelService

logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent


def create_app(test_config=None):
    app = Flask(__name__, instance_relative_config=False)

    model_dir = os.environ.get("MODEL_DIR", "model/artifacts")
    model_path = Path(model_dir)
    if not model_path.is_absolute():
        model_path = BASE_DIR / model_path

    app.config.from_mapping(
        SECRET_KEY=os.environ.get("SECRET_KEY", "dev-only-insecure-secret-key"),
        MODEL_DIR=str(model_path),
        MAX_CONTENT_LENGTH=128 * 1024 * 1024,  # 128 MB untuk mendukung dataset besar (200k+ baris)
        DB_HOST=os.environ.get("DB_HOST", "localhost"),
        DB_PORT=int(os.environ.get("DB_PORT", "3306")),
        DB_USER=os.environ.get("DB_USER", "root"),
        DB_PASSWORD=os.environ.get("DB_PASSWORD", ""),
        DB_NAME=os.environ.get("DB_NAME", "glucosafe"),
        SCREENING_USER_ID=int(os.environ.get("SCREENING_USER_ID", "1")),
    )

    if test_config:
        app.config.update(test_config)

    app.extensions["model_service"] = ModelService(app.config["MODEL_DIR"])

    from .routes.api import api_bp
    from .routes.pages import pages_bp

    app.register_blueprint(pages_bp)
    app.register_blueprint(api_bp, url_prefix="/api")

    @app.after_request
    def set_security_headers(response):
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault(
            "Content-Security-Policy",
            "default-src 'self'; style-src 'self'; img-src 'self' data:; "
            "script-src 'self'; form-action 'self'; frame-ancestors 'none'",
        )
        return response

    @app.context_processor
    def inject_model_status():
        return {"model_status": app.extensions["model_service"].status()}

    def _wants_json():
        return request.path.startswith("/api/") or request.is_json

    @app.errorhandler(400)
    def bad_request(error):
        message = getattr(error, "description", None) or "Permintaan tidak valid."
        if _wants_json():
            return (
                jsonify(
                    success=False,
                    error={"code": "BAD_REQUEST", "message": message},
                ),
                400,
            )
        return render_template("errors/400.html", message=message), 400

    @app.errorhandler(404)
    def not_found(error):
        if _wants_json():
            return (
                jsonify(
                    success=False,
                    error={"code": "NOT_FOUND", "message": "Endpoint tidak ditemukan."},
                ),
                404,
            )
        return render_template("errors/404.html"), 404

    @app.errorhandler(415)
    def unsupported_media_type(error):
        message = "Format permintaan harus application/json."
        if _wants_json():
            return (
                jsonify(
                    success=False,
                    error={"code": "UNSUPPORTED_MEDIA_TYPE", "message": message},
                ),
                415,
            )
        return render_template("errors/400.html", message=message), 415

    @app.errorhandler(500)
    def internal_error(error):
        logger.exception("Kesalahan internal: %s", error)
        if _wants_json():
            return (
                jsonify(
                    success=False,
                    error={
                        "code": "INTERNAL_ERROR",
                        "message": "Terjadi kesalahan pada server.",
                    },
                ),
                500,
            )
        return render_template("errors/500.html"), 500

    return app
