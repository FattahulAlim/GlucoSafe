"""Preprocessor artefak GlucoSafe (dipakai training & inference).

Menyatukan clipping outlier BMI dan scaling kolom kontinu agar urutan
transformasi saat training di ``ml-model/train_pipeline.py`` sama persis
dengan saat inferensi di ``ModelService``.

Kontrak: ``transform(X)`` menerima array ``(n, 15)`` sesuai urutan
``FEATURE_COLUMNS`` dan mengembalikan array float ``(n, 15)``.
"""

import numpy as np

# Indeks pada FEATURE_COLUMNS
BMI_INDEX = 2
SCALED_INDICES = (2, 9, 10, 11, 14)  # BMI, GenHlth, MentHlth, PhysHlth, Age


class FeaturePreprocessor:
    """Clip outlier BMI lalu scale kolom kontinu."""

    def __init__(self, scaler, bmi_low, bmi_high):
        self.scaler = scaler
        self.bmi_low = bmi_low
        self.bmi_high = bmi_high

    def transform(self, X):
        arr = np.array(X, dtype=float, copy=True)
        arr[:, BMI_INDEX] = np.clip(arr[:, BMI_INDEX], self.bmi_low, self.bmi_high)
        arr[:, SCALED_INDICES] = self.scaler.transform(arr[:, SCALED_INDICES])
        return arr
