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
        assert "Unduh Dataset Bersih (Cleaned CSV)" in html

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
