
async function predictDiabetesRisk(features) {
  if (process.env.ML_MOCK_MODE === 'true') {
    throw new Error('ML_MOCK_MODE tidak boleh digunakan untuk endpoint skrining nyata.');
  }

  const mlApiUrl = process.env.ML_API_URL;

  if (!mlApiUrl) {
    throw new Error('ML_API_URL belum dikonfigurasi.');
  }

  let endpoint;
  try {
    endpoint = new URL('/api/predict', mlApiUrl).toString();
  } catch {
    throw new Error('ML_API_URL tidak valid.');
  }

  let response;
  try {
    response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ features }),
      signal: AbortSignal.timeout(10000),
    });
  } catch (err) {
    throw new Error(`Gagal menghubungi ML API di ${mlApiUrl}: ${err.message}`);
  }

  if (!response.ok) {
    throw new Error(`ML API mengembalikan status ${response.status}.`);
  }

  let result;
  try {
    result = await response.json();
  } catch {
    throw new Error('Format JSON dari ML API tidak valid.');
  }
  // Flask mengirim score dalam persen (0-100), bukan probabilitas (0-1).
  const riskPercent = result?.score;
  const riskLabel = result?.prediction;

  if (
    result?.success !== true ||
    !Number.isFinite(riskPercent) ||
    riskPercent < 0 ||
    riskPercent > 100 ||
    !['Rendah', 'Sedang', 'Tinggi'].includes(riskLabel)
  ) {
    throw new Error('Format prediksi dari ML API tidak valid.');
  }

  return {
    risk_percent: riskPercent,
    risk_label: riskLabel,
    model_version: result.model_version,
  };
}

module.exports = { predictDiabetesRisk };
