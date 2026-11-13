"""Pipeline training GlucoSafe — migrasi dari Pengujian_Model_PBL_GlucoSafe.ipynb.

Alur identik notebook:
  load CSV -> buang fitur non-medis -> hapus duplikat -> split 80:20 stratified
  -> clip outlier BMI (batas IQR data train) -> StandardScaler 5 kolom
  -> training -> evaluasi -> ekspor artefak ke web-flask/model/artifacts.

Contoh:
  python ml-model/train_pipeline.py --data diabetes_binary_5050split_health_indicators_BRFSS2015.csv
  python ml-model/train_pipeline.py --data data.csv --model all
  python ml-model/train_pipeline.py --self-test

Dataset BRFSS 2015 tidak ikut repo; sediakan file CSV-nya sendiri.
Algoritma utama: ANN (sklearn MLPClassifier, 3 hidden layer 64-32-16).
"""

import argparse
import importlib.util
import json
import sys
import tempfile
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

ROOT = Path(__file__).resolve().parent.parent
WEB_FLASK = ROOT / "web-flask"
sys.path.insert(0, str(WEB_FLASK))


def _load_module(name, path):
    """Impor modul tanpa memicu ``glucosafe/__init__.py`` (yang butuh Flask)."""
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


_features = _load_module("glucosafe.features", WEB_FLASK / "glucosafe" / "features.py")
_preprocessing = _load_module(
    "glucosafe.preprocessing", WEB_FLASK / "glucosafe" / "preprocessing.py"
)
FEATURE_COLUMNS = _features.FEATURE_COLUMNS
FeaturePreprocessor = _preprocessing.FeaturePreprocessor

LABEL = "Diabetes_binary"
DROPPED = [
    "Income",
    "CholCheck",
    "HvyAlcoholConsump",
    "AnyHealthcare",
    "NoDocbcCost",
    "Education",
]
NUM_COLS = ["BMI", "Age", "GenHlth", "MentHlth", "PhysHlth"]
RANDOM_STATE = 42

ALGO_LABELS = {
    "ann": "Artificial Neural Network (MLPClassifier)",
    "rf": "Random Forest",
    "nb": "Gaussian Naive Bayes",
    "svm": "Support Vector Machine (RBF)",
    "knn": "K-Nearest Neighbors",
}
MODELS = list(ALGO_LABELS)


def load_dataset(path):
    df = pd.read_csv(path)
    missing = [c for c in FEATURE_COLUMNS + [LABEL] if c not in df.columns]
    if missing:
        raise SystemExit(f"Kolom wajib tidak ada di CSV: {missing}")

    df = df.drop(columns=[c for c in DROPPED if c in df.columns])
    before = len(df)
    df = df.drop_duplicates().reset_index(drop=True)
    print(f"Baris: {before} -> {len(df)} setelah hapus duplikat")

    df = df.astype({c: "int64" for c in df.columns if c != "BMI"})
    df["BMI"] = df["BMI"].astype(float)
    return df


def split_and_prepare(df):
    X = df[FEATURE_COLUMNS].copy()
    y = df[LABEL].astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
    )

    # Clip BMI memakai batas IQR data train saja (mencegah data leakage).
    q1, q3 = X_train["BMI"].quantile([0.25, 0.75])
    iqr = q3 - q1
    bmi_low, bmi_high = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    for part in (X_train, X_test):
        part["BMI"] = part["BMI"].clip(bmi_low, bmi_high)

    # Fit scaler memakai numpy array murni agar bebas warning nama fitur
    # (karena preprocessor menerima input array tanpa nama kolom saat inferensi).
    scaler = StandardScaler().fit(X_train[NUM_COLS].values)
    preprocessor = FeaturePreprocessor(scaler, bmi_low, bmi_high)

    print(
        f"Train {X_train.shape} | Test {X_test.shape} | "
        f"BMI clip [{bmi_low:.1f}, {bmi_high:.1f}]"
    )
    return X_train, X_test, y_train.values, y_test.values, preprocessor


def build_model(name):
    if name == "ann":
        return MLPClassifier(
            hidden_layer_sizes=(64, 32, 16),
            activation="relu",
            solver="adam",
            alpha=1e-4,
            max_iter=200,
            early_stopping=True,
            n_iter_no_change=10,
            random_state=RANDOM_STATE,
        )
    if name == "rf":
        return RandomForestClassifier(
            n_estimators=200, min_samples_leaf=5, random_state=RANDOM_STATE, n_jobs=-1
        )
    if name == "nb":
        return GaussianNB()
    if name == "svm":
        return SVC(kernel="rbf", C=1.0, gamma="scale")
    if name == "knn":
        return KNeighborsClassifier(n_neighbors=241)
    raise SystemExit(f"Model tidak dikenal: {name}")


def feature_matrices(name, X_train, X_test, preprocessor):
    """RF memakai fitur mentah (BMI sudah di-clip); sisanya hasil scaling."""
    if name == "rf":
        return X_train.values, X_test.values
    return preprocessor.transform(X_train.values), preprocessor.transform(X_test.values)


def evaluate(model, X_test, y_test):
    started = time.perf_counter()
    y_pred = model.predict(X_test)
    predict_seconds = time.perf_counter() - started

    if hasattr(model, "predict_proba"):
        scores = model.predict_proba(X_test)[:, 1]
    elif hasattr(model, "decision_function"):
        scores = model.decision_function(X_test)  # SVM: skor, bukan probabilitas
    else:
        scores = y_pred

    return {
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "f1": float(f1_score(y_test, y_pred, zero_division=0)),
        "roc_auc": float(roc_auc_score(y_test, scores)),
        "predict_seconds": round(predict_seconds, 3),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
    }


def export(name, model, preprocessor, metrics, out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, out / "model.joblib")
    joblib.dump(preprocessor, out / "preprocessor.joblib")

    metadata = {
        "version": f"v1.1-{name}",
        "algorithm": ALGO_LABELS[name],
        "features": FEATURE_COLUMNS,
        "label_map": {"0": "Rendah", "1": "Tinggi"},
        "thresholds": {"medium": 35.0, "high": 65.0},
        "metrics": {
            key: round(metrics[key], 4)
            for key in ("accuracy", "precision", "recall", "f1", "roc_auc")
        },
    }
    (out / "metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    if not hasattr(model, "predict_proba"):
        print(f"PERINGATAN: {name} tidak punya predict_proba, pred_score di web kosong.")
    print(f"Artefak disimpan ke {out}")


def self_test():
    n = 240
    rng = np.random.default_rng(0)
    df = pd.DataFrame({col: rng.integers(0, 2, n) for col in FEATURE_COLUMNS})
    df["BMI"] = rng.normal(28, 5, n).clip(12, 60)
    df["GenHlth"] = rng.integers(1, 6, n)
    df["MentHlth"] = rng.integers(0, 31, n)
    df["PhysHlth"] = rng.integers(0, 31, n)
    df["Age"] = rng.integers(1, 14, n)
    df[LABEL] = rng.integers(0, 2, n)
    for col in DROPPED:
        df[col] = 1

    tmp = Path(tempfile.mkdtemp(prefix="glucosafe_selftest_"))
    csv_path = tmp / "synthetic.csv"
    df.to_csv(csv_path, index=False)

    data = load_dataset(csv_path)
    X_train, X_test, y_train, y_test, preprocessor = split_and_prepare(data)
    X_train_p, X_test_p = feature_matrices("ann", X_train, X_test, preprocessor)
    assert X_train_p.shape == (len(X_train), len(FEATURE_COLUMNS))

    model = build_model("rf")
    model.n_estimators = 5
    model.fit(X_train.values, y_train)
    metrics = evaluate(model, X_test.values, y_test)
    assert 0.0 <= metrics["accuracy"] <= 1.0
    assert len(metrics["confusion_matrix"]) == 2

    export("rf", model, preprocessor, metrics, tmp / "artifacts")
    pre_loaded = joblib.load(tmp / "artifacts" / "preprocessor.joblib")
    model_loaded = joblib.load(tmp / "artifacts" / "model.joblib")
    assert pre_loaded.transform(X_test.values).shape == X_test_p.shape
    assert model_loaded.predict(X_test.values[:5]).shape == (5,)
    print("\nSelf-test OK: preprocessing, training, export, dan load round-trip.")
    return 0


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--data", help="Path CSV BRFSS 2015")
    parser.add_argument(
        "--model", default="ann", choices=MODELS + ["all"], help="Algoritma (default: ann)"
    )
    parser.add_argument(
        "--out",
        default=str(WEB_FLASK / "model" / "artifacts"),
        help="Folder artefak (default: web-flask/model/artifacts)",
    )
    parser.add_argument("--self-test", action="store_true", help="Uji alur dengan data sintetis")
    args = parser.parse_args()

    if args.self_test:
        return self_test()
    if not args.data:
        raise SystemExit("--data wajib diisi (path CSV BRFSS 2015).")

    df = load_dataset(args.data)
    X_train, X_test, y_train, y_test, preprocessor = split_and_prepare(df)

    names = MODELS if args.model == "all" else [args.model]
    results = {}
    for name in names:
        X_tr, X_te = feature_matrices(name, X_train, X_test, preprocessor)
        model = build_model(name)

        started = time.perf_counter()
        model.fit(X_tr, y_train)
        train_seconds = time.perf_counter() - started

        metrics = evaluate(model, X_te, y_test)
        results[name] = metrics
        print(
            f"[{name.upper():3}] acc={metrics['accuracy']:.4f} "
            f"prec={metrics['precision']:.4f} rec={metrics['recall']:.4f} "
            f"f1={metrics['f1']:.4f} roc={metrics['roc_auc']:.4f} "
            f"train={train_seconds:.1f}s pred={metrics['predict_seconds']}s"
        )
        print(f"       confusion_matrix={metrics['confusion_matrix']}")

        if args.model != "all":
            export(name, model, preprocessor, metrics, args.out)

    if args.model == "all":
        best = max(results, key=lambda k: results[k]["roc_auc"])
        print(f"\nROC-AUC tertinggi: {best.upper()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
