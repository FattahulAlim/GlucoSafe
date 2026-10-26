"""Model service abstraction for GlucoSafe.

Mematuhi ketentuan PRD:
- Tidak mengunci satu jenis algoritma (ANN, Naive Bayes, SVM, dsb).
- Jika artefak model belum tersedia di model/artifacts, status: model_ready=False.
- API mengembalikan 503 saat model belum siap; TIDAK MENGHASILKAN PREDIKSI PALSU.
- Saat model tersedia (joblib/pickle atau custom pipeline), memuat preprocessing
  dan menghasilkan label, versi model, dan skor opsional.
"""

import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from .features import FEATURE_COLUMNS

logger = logging.getLogger(__name__)


@dataclass
class PredictionResult:
    risk_label: str
    model_version: str
    risk_percent: Optional[float] = None
    confidence_score: Optional[float] = None
    is_dummy: bool = False


class ModelService:
    def __init__(self, artifacts_dir: str):
        self.artifacts_dir = Path(artifacts_dir)
        self.model = None
        self.preprocessor = None
        self.metadata: Dict[str, Any] = {}
        self.load_error: Optional[str] = None
        self._load()

    def _load(self):
        """Mencari dan memuat artefak model jika tersedia."""
        if not self.artifacts_dir.exists():
            self.load_error = f"Direktori artefak {self.artifacts_dir} belum dibuat."
            return

        metadata_file = self.artifacts_dir / "metadata.json"
        if metadata_file.is_file():
            try:
                with open(metadata_file, "r", encoding="utf-8") as f:
                    self.metadata = json.load(f)
            except Exception as e:
                logger.warning("Gagal membaca metadata model: %s", e)

        # Mencari artefak model scikit-learn / joblib / pickle
        model_candidates = list(self.artifacts_dir.glob("model*.joblib")) + list(
            self.artifacts_dir.glob("model*.pkl")
        )

        if not model_candidates:
            self.load_error = "Artefak model belum tersedia di direktori model/artifacts."
            return

        chosen_model_file = model_candidates[0]
        try:
            import joblib  # type: ignore

            self.model = joblib.load(chosen_model_file)
            logger.info("Model berhasil dimuat dari %s", chosen_model_file)
        except ImportError:
            self.load_error = (
                "Paket machine learning belum terpasang. Jalankan: pip install -r requirements-ml.txt"
            )
            return
        except Exception as e:
            self.load_error = f"Gagal memuat file model: {e}"
            logger.exception("Error loading model: %s", e)
            return

        # Mencari preprocessor opsional (scaler, pipeline)
        preprocessor_candidates = list(
            self.artifacts_dir.glob("scaler*.joblib")
        ) + list(self.artifacts_dir.glob("preprocessor*.joblib"))
        if preprocessor_candidates:
            try:
                import joblib  # type: ignore

                self.preprocessor = joblib.load(preprocessor_candidates[0])
            except Exception as e:
                logger.warning("Gagal memuat preprocessor: %s", e)

    @property
    def is_ready(self) -> bool:
        return self.model is not None

    @property
    def version(self) -> str:
        if not self.is_ready:
            return "none"
        return self.metadata.get("version", "v1.0")

    def status(self) -> Dict[str, Any]:
        return {
            "model_ready": self.is_ready,
            "version": self.version if self.is_ready else None,
            "algorithm": self.metadata.get("algorithm") if self.is_ready else None,
            "feature_count": len(FEATURE_COLUMNS),
            "message": (
                "Model siap digunakan."
                if self.is_ready
                else (self.load_error or "Model belum tersedia.")
            ),
        }

    def predict(self, features: Dict[str, Any]) -> PredictionResult:
        """Menjalankan inferensi model terlatih.

        Menolak jika model belum tersedia; tidak menghasilkan data dummy.
        """
        if not self.is_ready:
            raise RuntimeError(
                self.load_error or "Model belum tersedia. Prediksi tidak dapat dijalankan."
            )

        # Buat vektor fitur terurut sesuai FEATURE_COLUMNS
        row = [features[col] for col in FEATURE_COLUMNS]

        import numpy as np  # type: ignore

        x = np.array([row])

        if self.preprocessor is not None:
            x = self.preprocessor.transform(x)

        # Prediksi label
        raw_pred = self.model.predict(x)[0]

        # Probabilitas / confidence jika didukung
        risk_percent: Optional[float] = None
        confidence: Optional[float] = None

        if hasattr(self.model, "predict_proba"):
            try:
                proba = self.model.predict_proba(x)[0]
                # Jika binary classification: proba kelas 1 = probabilitas diabetes
                if len(proba) == 2:
                    p = float(proba[1])
                    risk_percent = round(p * 100.0, 2)
                    confidence = round(p, 4)
                elif len(proba) > 2:
                    # Multi-class
                    confidence = round(float(np.max(proba)), 4)
            except Exception as e:
                logger.warning("predict_proba gagal: %s", e)

        # Pemetaan label standar GlucoSafe
        label_map = self.metadata.get("label_map", {})
        if str(raw_pred) in label_map:
            label = label_map[str(raw_pred)]
        elif raw_pred in (1, "1", "High", "Tinggi", "diabetes"):
            label = "Tinggi"
        elif raw_pred in (0, "0", "Low", "Rendah", "no_diabetes"):
            label = "Rendah"
        else:
            label = str(raw_pred)

        # Jika model menghasilkan skor persentase tapi belum ada label bertingkat 3 (Rendah/Sedang/Tinggi)
        if risk_percent is not None and "thresholds" in self.metadata:
            t = self.metadata["thresholds"]
            mid_th = t.get("medium", 30.0)
            high_th = t.get("high", 65.0)
            if risk_percent < mid_th:
                label = "Rendah"
            elif risk_percent < high_th:
                label = "Sedang"
            else:
                label = "Tinggi"

        return PredictionResult(
            risk_label=label,
            model_version=self.version,
            risk_percent=risk_percent,
            confidence_score=confidence,
            is_dummy=False,
        )

    def predict_matrix(self, rows_list: List[List[Any]]) -> List[Dict[str, Any]]:
        """Menjalankan inferensi massal untuk matriks fitur 2D (vektorisasi numpy).

        Sangat efisien untuk 10.000 - 250.000 baris sekaligus tanpa looping python per baris.
        """
        if not self.is_ready:
            raise RuntimeError(
                self.load_error or "Model belum tersedia. Prediksi tidak dapat dijalankan."
            )

        import numpy as np  # type: ignore

        x = np.array(rows_list)
        if self.preprocessor is not None:
            x = self.preprocessor.transform(x)

        raw_preds = self.model.predict(x)

        # Cek predict_proba massal
        probas = None
        if hasattr(self.model, "predict_proba"):
            try:
                p_arr = np.asarray(self.model.predict_proba(x))
                if p_arr.ndim == 2 and p_arr.shape[1] == 2:
                    probas = p_arr[:, 1]
            except Exception as e:
                logger.warning("predict_proba massal gagal: %s", e)

        label_map = self.metadata.get("label_map", {})
        thresholds = self.metadata.get("thresholds")
        version = self.version

        results = []
        for i in range(len(raw_preds)):
            raw_p = raw_preds[i]
            r_str = str(raw_p)

            p_val = float(probas[i]) if probas is not None else None
            score_pct = round(p_val * 100.0, 2) if p_val is not None else None

            if r_str in label_map:
                lbl = label_map[r_str]
            elif raw_p in (1, "1", "High", "Tinggi", "diabetes"):
                lbl = "Tinggi"
            elif raw_p in (0, "0", "Low", "Rendah", "no_diabetes"):
                lbl = "Rendah"
            else:
                lbl = r_str

            if score_pct is not None and thresholds:
                mid_th = thresholds.get("medium", 30.0)
                high_th = thresholds.get("high", 65.0)
                if score_pct < mid_th:
                    lbl = "Rendah"
                elif score_pct < high_th:
                    lbl = "Sedang"
                else:
                    lbl = "Tinggi"

            results.append(
                {
                    "label": lbl,
                    "score": score_pct,
                    "version": version,
                }
            )

        return results
