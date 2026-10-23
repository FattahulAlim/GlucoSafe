"""Kontrak fitur dan validasi data GlucoSafe.

Kontrak ini dipakai bersama oleh dashboard olah data, API JSON, dan aplikasi
mobile (Flutter). Nama fitur mengikuti dataset BRFSS 2015 Diabetes Health
Indicators (15 fitur + BMI).
"""

import re
from typing import Any, Dict, List, Optional, Tuple

FEATURE_COLUMNS: List[str] = [
    "HighBP",
    "HighChol",
    "BMI",
    "Smoker",
    "Stroke",
    "HeartDiseaseorAttack",
    "PhysActivity",
    "Fruits",
    "Veggies",
    "GenHlth",
    "MentHlth",
    "PhysHlth",
    "DiffWalk",
    "Sex",
    "Age",
]

HEIGHT_COLUMN = "height_cm"
WEIGHT_COLUMN = "weight_kg"

MIN_HEIGHT_CM = 100.0
MAX_HEIGHT_CM = 220.0
MIN_WEIGHT_KG = 30.0
MAX_WEIGHT_KG = 250.0
MIN_BMI = 6.2
MAX_BMI = 250.0

_HEADER_ALIASES: Dict[str, str] = {
    "highbp": "HighBP",
    "highchol": "HighChol",
    "bmi": "BMI",
    "smoker": "Smoker",
    "stroke": "Stroke",
    "heartdiseaseorattack": "HeartDiseaseorAttack",
    "heartdisease": "HeartDiseaseorAttack",
    "heartattack": "HeartDiseaseorAttack",
    "physactivity": "PhysActivity",
    "physicalactivity": "PhysActivity",
    "fruits": "Fruits",
    "veggies": "Veggies",
    "vegetables": "Veggies",
    "genhlth": "GenHlth",
    "generalhealth": "GenHlth",
    "menthlth": "MentHlth",
    "mentalhealth": "MentHlth",
    "physhlth": "PhysHlth",
    "physicalhealth": "PhysHlth",
    "diffwalk": "DiffWalk",
    "difficultywalking": "DiffWalk",
    "sex": "Sex",
    "gender": "Sex",
    "age": "Age",
    "heightcm": HEIGHT_COLUMN,
    "height": HEIGHT_COLUMN,
    "weightkg": WEIGHT_COLUMN,
    "weight": WEIGHT_COLUMN,
}


def canonical_header(header: str) -> Optional[str]:
    key = re.sub(r"[\s_\-]+", "", str(header or "")).lower()
    return _HEADER_ALIASES.get(key)


def calculate_bmi(height_cm: float, weight_kg: float) -> float:
    height_m = height_cm / 100.0
    return round(weight_kg / (height_m * height_m), 1)


def _to_number(value: Any, label: str, errors: Dict[str, str]) -> Optional[float]:
    if value is None or value == "":
        errors[label] = f"{label} wajib diisi."
        return None
    if isinstance(value, bool):
        errors[label] = f"{label} harus berupa angka."
        return None
    if isinstance(value, str):
        value = value.strip().replace(",", ".")
    try:
        number = float(value)
    except (TypeError, ValueError):
        errors[label] = f"{label} harus berupa angka."
        return None
    if number != number or number in (float("inf"), float("-inf")):
        errors[label] = f"{label} harus berupa angka berhingga."
        return None
    return number


def _to_int(value: Any, label: str, minimum: int, maximum: int, errors: Dict[str, str]) -> Optional[int]:
    number = _to_number(value, label, errors)
    if number is None:
        return None
    if not float(number).is_integer():
        errors[label] = f"{label} harus berupa bilangan bulat."
        return None
    result = int(number)
    if result < minimum or result > maximum:
        errors[label] = f"{label} harus antara {minimum} dan {maximum}."
        return None
    return result


def _to_float(value: Any, label: str, minimum: float, maximum: float, errors: Dict[str, str]) -> Optional[float]:
    number = _to_number(value, label, errors)
    if number is None:
        return None
    if number < minimum or number > maximum:
        errors[label] = f"{label} harus antara {minimum:g} dan {maximum:g}."
        return None
    return number


def normalize_row(raw_row: Dict[str, Any]) -> Dict[str, Any]:
    normalized: Dict[str, Any] = {}
    for header, value in raw_row.items():
        canonical = canonical_header(header)
        if canonical and canonical not in normalized:
            normalized[canonical] = value
    return normalized


def validate_features(raw_features: Any) -> Tuple[Optional[Dict[str, Any]], Dict[str, str]]:
    if not isinstance(raw_features, dict):
        return None, {"features": "Data fitur harus berupa objek."}

    normalized = normalize_row(raw_features)
    errors: Dict[str, str] = {}

    if "BMI" not in normalized:
        height = normalized.get(HEIGHT_COLUMN)
        weight = normalized.get(WEIGHT_COLUMN)
        if height not in (None, "") and weight not in (None, ""):
            parsed_height = _to_float(height, HEIGHT_COLUMN, MIN_HEIGHT_CM, MAX_HEIGHT_CM, errors)
            parsed_weight = _to_float(weight, WEIGHT_COLUMN, MIN_WEIGHT_KG, MAX_WEIGHT_KG, errors)
            if parsed_height is not None and parsed_weight is not None:
                normalized["BMI"] = calculate_bmi(parsed_height, parsed_weight)

    binary_fields = [
        "HighBP",
        "HighChol",
        "Smoker",
        "Stroke",
        "HeartDiseaseorAttack",
        "PhysActivity",
        "Fruits",
        "Veggies",
        "DiffWalk",
        "Sex",
    ]

    cleaned: Dict[str, Any] = {}
    for field in binary_fields:
        value = _to_int(normalized.get(field), field, 0, 1, errors)
        if value is not None:
            cleaned[field] = value

    for field, minimum, maximum in (
        ("Age", 1, 13),
        ("GenHlth", 1, 5),
        ("MentHlth", 0, 30),
        ("PhysHlth", 0, 30),
    ):
        value = _to_int(normalized.get(field), field, minimum, maximum, errors)
        if value is not None:
            cleaned[field] = value

    bmi = _to_float(normalized.get("BMI"), "BMI", MIN_BMI, MAX_BMI, errors)
    if bmi is not None:
        cleaned["BMI"] = round(bmi, 1)

    if errors:
        return None, errors

    return cleaned, {}


validate_api_features = validate_features
