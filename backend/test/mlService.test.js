const test = require('node:test');
const assert = require('node:assert/strict');
const { predictDiabetesRisk } = require('../src/services/mlService');

const features = {
  HighBP: 0,
  HighChol: 0,
  BMI: 24.8,
  Smoker: 0,
  Stroke: 0,
  HeartDiseaseorAttack: 0,
  PhysActivity: 1,
  Fruits: 1,
  Veggies: 1,
  GenHlth: 2,
  MentHlth: 0,
  PhysHlth: 0,
  DiffWalk: 0,
  Sex: 0,
  Age: 3,
};

const originalFetch = global.fetch;
const originalUrl = process.env.ML_API_URL;
const originalMockMode = process.env.ML_MOCK_MODE;

test.afterEach(() => {
  global.fetch = originalFetch;
  if (originalUrl === undefined) delete process.env.ML_API_URL;
  else process.env.ML_API_URL = originalUrl;
  if (originalMockMode === undefined) delete process.env.ML_MOCK_MODE;
  else process.env.ML_MOCK_MODE = originalMockMode;
});

test('memanggil Flask /api/predict dan memetakan respons nyata', async () => {
  process.env.ML_API_URL = 'http://127.0.0.1:5000';
  delete process.env.ML_MOCK_MODE;
  let request;
  global.fetch = async (url, options) => {
    request = { url, options };
    return new Response(JSON.stringify({
      success: true,
      prediction: 'Sedang',
      score: 42.5,
      model_version: 'v1.2',
    }), { status: 200 });
  };

  const result = await predictDiabetesRisk(features);

  assert.equal(request.url, 'http://127.0.0.1:5000/api/predict');
  assert.deepEqual(JSON.parse(request.options.body), { features });
  assert.deepEqual(result, {
    risk_percent: 42.5,
    risk_label: 'Sedang',
    model_version: 'v1.2',
  });
});

test('menolak mode mock pada endpoint skrining nyata', async () => {
  process.env.ML_MOCK_MODE = 'true';
  await assert.rejects(
    () => predictDiabetesRisk(features),
    /ML_MOCK_MODE tidak boleh digunakan/,
  );
});

test('menolak respons ML tanpa skor valid', async () => {
  process.env.ML_API_URL = 'http://127.0.0.1:5000';
  delete process.env.ML_MOCK_MODE;
  global.fetch = async () => new Response(JSON.stringify({
    success: true,
    prediction: 'Rendah',
  }), { status: 200 });

  await assert.rejects(
    () => predictDiabetesRisk(features),
    /Format prediksi dari ML API tidak valid/,
  );
});
