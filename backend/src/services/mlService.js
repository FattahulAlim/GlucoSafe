
/**
 * Hitung mock risk berdasarkan fitur — dipakai saat ML_MOCK_MODE=true.
 * Bukan model nyata; hanya untuk keperluan testing integrasi FE↔BE.
 */
function _mockPredict(features) {
  let score = 0;
  if (features.HighBP === 1)             score += 15;
  if (features.HighChol === 1)           score += 10;
  if (features.BMI > 30)                 score += 15;
  else if (features.BMI > 25)            score += 8;
  if (features.Smoker === 1)             score += 8;
  if (features.Stroke === 1)             score += 12;
  if (features.HeartDiseaseorAttack === 1) score += 12;
  if (features.PhysActivity === 0)       score += 8;
  if (features.Fruits === 0)             score += 3;
  if (features.Veggies === 0)            score += 3;
  if (features.GenHlth >= 4)             score += 10;
  if (features.Age >= 9)                 score += 10;

  const risk_percent = Math.min(Math.round(score), 100);
  const risk_label =
    risk_percent >= 60 ? 'Tinggi' :
    risk_percent >= 30 ? 'Sedang' : 'Rendah';

  return { risk_percent, risk_label };
}

async function predictDiabetesRisk(features) {
  // Mode mock untuk testing integrasi saat ML API belum tersedia.
  if (process.env.ML_MOCK_MODE === 'true') {
    console.log('[mlService] ML_MOCK_MODE aktif — menggunakan prediksi mock.');
    return _mockPredict(features);
  }

  const mlApiUrl = process.env.ML_API_URL;

  if (!mlApiUrl) {
    throw new Error('ML_API_URL belum dikonfigurasi.');
  }

  const response = await fetch(`${mlApiUrl}/predict`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(features),
    signal: AbortSignal.timeout(10000),
  });

  if (!response.ok) {
    throw new Error(`ML API mengembalikan status ${response.status}.`);
  }

  const result = await response.json();

  if (
    typeof result.risk_percent !== 'number' ||
    !Number.isFinite(result.risk_percent) ||
    result.risk_percent < 0 ||
    result.risk_percent > 100 ||
    !['Rendah', 'Sedang', 'Tinggi'].includes(result.risk_label)
  ) {
    throw new Error('Format prediksi dari ML API tidak valid.');
  }

  return result;
}

module.exports = { predictDiabetesRisk };
