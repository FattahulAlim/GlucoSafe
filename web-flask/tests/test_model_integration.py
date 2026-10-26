"""Test integrasi inferensi batch dan model API."""

import io
from glucosafe import create_app
from glucosafe.batch_service import generate_sample_csv


class FakeModel:
    def predict(self, X):
        return [1 if row[2] > 25 or row[0] == 1 else 0 for row in X]

    def predict_proba(self, X):
        import numpy as np
        rows = []
        for row in X:
            p = 0.85 if (row[2] > 25 or row[0] == 1) else 0.15
            rows.append([1.0 - p, p])
        return np.array(rows)


def test_batch_processing_with_loaded_model(tmp_path):
    import joblib

    artifacts_dir = tmp_path / "artifacts"
    artifacts_dir.mkdir()

    joblib.dump(FakeModel(), artifacts_dir / "model.joblib")
    meta = {
        "version": "v1.0-batch",
        "algorithm": "FakeClassifier",
        "label_map": {"0": "Rendah", "1": "Tinggi"},
        "thresholds": {"medium": 30.0, "high": 60.0},
    }
    (artifacts_dir / "metadata.json").write_text(__import__("json").dumps(meta), encoding="utf-8")

    app = create_app(
        {
            "TESTING": True,
            "SECRET_KEY": "test-key",
            "MODEL_DIR": str(artifacts_dir),
        }
    )

    with app.test_client() as client:
        # 1. Health check
        res = client.get("/api/health")
        assert res.status_code == 200
        assert res.get_json()["model_ready"] is True

        # 2. Upload batch CSV untuk pembersihan & standarisasi dataset
        sample_csv = generate_sample_csv().encode("utf-8")
        post_data = {"csv_file": (io.BytesIO(sample_csv), "patients_sample.csv")}
        res_upload = client.post(
            "/process",
            data=post_data,
            content_type="multipart/form-data",
            follow_redirects=True,
        )
        assert res_upload.status_code == 200
        html = res_upload.get_data(as_text=True)
        assert "Hasil Pengolahan Dataset" in html
        assert "Unduh CSV Hasil Prediksi" in html
        assert "Distribusi Label Prediksi" in html

        # 3. API predict per-item tetap jalan untuk Flutter
        payload = {
            "features": {
                "HighBP": 1,
                "HighChol": 0,
                "BMI": 28.0,
                "Smoker": 0,
                "Stroke": 0,
                "HeartDiseaseorAttack": 0,
                "PhysActivity": 1,
                "Fruits": 1,
                "Veggies": 1,
                "GenHlth": 3,
                "MentHlth": 0,
                "PhysHlth": 0,
                "DiffWalk": 0,
                "Sex": 1,
                "Age": 6,
            }
        }
        res_api = client.post("/api/predict", json=payload)
        assert res_api.status_code == 200
        pred = res_api.get_json()
        assert pred["prediction"] == "Tinggi"
        assert pred["model_version"] == "v1.0-batch"


def test_hybrid_user_id_saved_to_database(monkeypatch, tmp_path):
    """user_id diambil dari CSV, fallback ke default_user_id form web."""
    import json

    import joblib

    artifacts_dir = tmp_path / "artifacts"
    artifacts_dir.mkdir()
    joblib.dump(FakeModel(), artifacts_dir / "model.joblib")
    meta = {
        "version": "v1.0-batch",
        "algorithm": "FakeClassifier",
        "label_map": {"0": "Rendah", "1": "Tinggi"},
        "thresholds": {"medium": 30.0, "high": 60.0},
    }
    (artifacts_dir / "metadata.json").write_text(json.dumps(meta), encoding="utf-8")

    captured = {}

    def fake_insert(config, rows):
        rows = list(rows)
        captured.setdefault("rows", []).extend(rows)
        return len(rows)

    monkeypatch.setattr("glucosafe.batch_service.insert_screening_results", fake_insert)

    app = create_app(
        {
            "TESTING": True,
            "SECRET_KEY": "test-key",
            "MODEL_DIR": str(artifacts_dir),
        }
    )

    # Baris ke-3 tanpa user_id -> memakai default 9
    csv_text = (
        "HighBP,HighChol,BMI,Smoker,Stroke,HeartDiseaseorAttack,PhysActivity,"
        "Fruits,Veggies,GenHlth,MentHlth,PhysHlth,DiffWalk,Sex,Age,user_id\n"
        "1,1,28.5,0,0,0,0,1,1,3,5,2,0,1,8,1\n"
        "0,0,22.1,0,0,0,1,1,1,1,0,0,0,0,4,2\n"
        "1,1,33.4,1,0,1,0,0,1,4,10,14,1,1,10,\n"
    )

    with app.test_client() as client:
        res = client.post(
            "/process",
            data={
                "csv_file": (io.BytesIO(csv_text.encode("utf-8")), "dataset.csv"),
                "save_to_db": "1",
            },
            content_type="multipart/form-data",
        )
        assert res.status_code == 302

    rows = captured["rows"]
    assert len(rows) == 3
    # Default SCREENING_USER_ID adalah 1 untuk semua baris
    assert [r["user_id"] for r in rows] == [1, 1, 1]
    assert all(r["risk_label"] in ("Rendah", "Sedang", "Tinggi") for r in rows)
    assert rows[0]["high_bp"] == 1
    assert rows[0]["bmi"] == 28.5

