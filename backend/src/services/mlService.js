
async function predictDiabetesRisk(features) {
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
