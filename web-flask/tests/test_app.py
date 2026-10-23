"""Pengujian unit dan integrasi untuk dashboard olah data dan API GlucoSafe."""

import io
import pytest

from glucosafe import create_app
from glucosafe.batch_service import generate_sample_csv, process_batch
from glucosafe.features import calculate_bmi, validate_features


@pytest.fixture
def client(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SECRET_KEY": "test-secret-key",
            "MODEL_DIR": str(tmp_path / "empty_artifacts"),
        }
    )
    (tmp_path / "empty_artifacts").mkdir(parents=True, exist_ok=True)
    with app.test_client() as client:
        yield client


def test_calculate_bmi():
    assert calculate_bmi(165.0, 70.0) == 25.7


def test_validate_features_valid():
    payload = {
        "HighBP": 0,
        "HighChol": 0,
        "BMI": 25.7,
        "Smoker": 0,
        "Stroke": 0,
        "HeartDiseaseorAttack": 0,
        "PhysActivity": 1,
        "Fruits": 1,
        "Veggies": 1,
        "GenHlth": 2,
        "MentHlth": 0,
        "PhysHlth": 0,
        "DiffWalk": 0,
        "Sex": 1,
        "Age": 5,
    }
    cleaned, errors = validate_features(payload)
    assert not errors
    assert cleaned["HighBP"] == 0
    assert cleaned["BMI"] == 25.7


def test_validate_features_derives_bmi_from_height_and_weight():
    payload = {
        "high_bp": 0,
        "high_chol": 0,
        "height_cm": 170,
        "weight_kg": 68,
        "smoker": 0,
        "stroke": 0,
        "heart_disease": 0,
        "phys_activity": 1,
        "fruits": 1,
        "veggies": 1,
        "gen_hlth": 2,
        "ment_hlth": 0,
        "phys_hlth": 0,
        "diff_walk": 0,
        "sex": 1,
        "age": 4,
    }
    cleaned, errors = validate_features(payload)
    assert not errors
    assert cleaned["BMI"] == 23.5


def test_home_page_shows_data_dashboard(client):
    res = client.get("/")
    assert res.status_code == 200
    html = res.get_data(as_text=True)
    assert "Pengolahan Data" in html
    assert "Unggah Dataset CSV" in html


def test_sample_csv_download(client):
    res = client.get("/sample.csv")
    assert res.status_code == 200
    assert res.mimetype == "text/csv"
    assert "HighBP,HighChol,BMI" in res.get_data(as_text=True)


def test_process_csv_upload_and_download(client):
    sample = generate_sample_csv().encode("utf-8")
    data = {"csv_file": (io.BytesIO(sample), "test_data.csv")}
    res = client.post("/process", data=data, content_type="multipart/form-data", follow_redirects=True)
    assert res.status_code == 200
    html = res.get_data(as_text=True)
    assert "Hasil Pengolahan Dataset" in html
    assert "test_data.csv" in html


def test_api_health_endpoint(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    body = res.get_json()
    assert body["success"] is True
    assert body["model_ready"] is False
    assert len(body["expected_features"]) == 15


def test_api_predict_when_model_not_ready_returns_503(client):
    payload = {
        "features": {
            "HighBP": 0,
            "HighChol": 0,
            "BMI": 25.7,
            "Smoker": 0,
            "Stroke": 0,
            "HeartDiseaseorAttack": 0,
            "PhysActivity": 1,
            "Fruits": 1,
            "Veggies": 1,
            "GenHlth": 2,
            "MentHlth": 0,
            "PhysHlth": 0,
            "DiffWalk": 0,
            "Sex": 1,
            "Age": 5,
        }
    }
    res = client.post("/api/predict", json=payload)
    assert res.status_code == 503
    body = res.get_json()
    assert body["success"] is False
    assert body["error"]["code"] == "MODEL_NOT_READY"


def test_fixed_user_id_extraction():
    from glucosafe.batch_service import _extract_user_id

    # Mode user tetap: semua baris memakai user default
    assert _extract_user_id({"user_id": "42"}, default_user_id=1) == 1
    assert _extract_user_id({"UserId": 7}, default_user_id=1) == 1

    # Tanpa default: nilai CSV dipakai (fallback)
    assert _extract_user_id({"UserId": 7}, default_user_id=None) == 7
    assert _extract_user_id({}, default_user_id=5) == 5
    assert _extract_user_id({}, default_user_id=None) is None
