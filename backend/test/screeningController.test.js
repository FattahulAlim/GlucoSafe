const test = require('node:test');
const assert = require('node:assert/strict');
const db = require('../src/config/database');
const {
  predictScreening,
  submitScreening,
  getScreeningHistory,
  getScreeningDetail,
  getScreeningRecommendations,
} = require('../src/controllers/screeningController');

function createMockRes() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
  };
}

const validBody = {
  sex: 1,
  age: 5,
  height_cm: 170,
  weight_kg: 70,
  high_bp: 0,
  high_chol: 0,
  stroke: 0,
  heart_disease: 0,
  diff_walk: 0,
  smoker: 0,
  phys_activity: 1,
  fruits: 1,
  veggies: 1,
  gen_hlth: 2,
  ment_hlth: 0,
  phys_hlth: 0,
};

const originalExecute = db.execute;
const originalQuery = db.query;
const originalFetch = global.fetch;
const originalMlUrl = process.env.ML_API_URL;
const originalMockMode = process.env.ML_MOCK_MODE;

test.beforeEach(() => {
  process.env.ML_API_URL = 'http://127.0.0.1:5000';
  delete process.env.ML_MOCK_MODE;
});

test.afterEach(() => {
  db.execute = originalExecute;
  db.query = originalQuery;
  global.fetch = originalFetch;
  if (originalMlUrl === undefined) delete process.env.ML_API_URL;
  else process.env.ML_API_URL = originalMlUrl;
  if (originalMockMode === undefined) delete process.env.ML_MOCK_MODE;
  else process.env.ML_MOCK_MODE = originalMockMode;
});

test('screeningController.predictScreening: tolak input tidak valid (400)', async () => {
  const req = { body: { sex: 99 } }; // invalid fields
  const res = createMockRes();

  await predictScreening(req, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.success, false);
  assert.ok(res.body.errors);
});

test('screeningController.predictScreening: kembalikan hasil prediksi dan rekomendasi (200)', async () => {
  global.fetch = async () => new Response(JSON.stringify({
    success: true,
    prediction: 'Rendah',
    score: 12.4,
    model_version: 'v1.0-svm',
  }), { status: 200 });

  const req = { body: { ...validBody } };
  const res = createMockRes();

  await predictScreening(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.risk_percent, 12.4);
  assert.equal(res.body.data.risk_label, 'Rendah');
  assert.equal(res.body.data.bmi, 24.2);
  assert.ok(Array.isArray(res.body.data.recommendations));
  assert.ok(res.body.data.recommendations.length > 0);
});

test('screeningController.predictScreening: 502 saat ML API tidak terjangkau', async () => {
  global.fetch = async () => {
    throw new Error('ECONNREFUSED');
  };

  const req = { body: { ...validBody } };
  const res = createMockRes();

  await predictScreening(req, res);

  assert.equal(res.statusCode, 502);
  assert.equal(res.body.success, false);
});

test('screeningController.submitScreening: simpan hasil skrining & rekomendasi ke DB (201)', async () => {
  let savedRecommendations = [];
  db.execute = async (sql) => {
    if (sql.includes('INSERT INTO screening_results')) {
      return [{ insertId: 101 }];
    }
    if (sql.includes('SELECT id, created_at FROM screening_results')) {
      return [[{ id: 101, created_at: '2026-11-10T10:00:00Z' }]];
    }
    return [[]];
  };
  db.query = async (sql, values) => {
    if (sql.includes('INSERT INTO recommendations')) {
      savedRecommendations = values[0];
      return [{ affectedRows: savedRecommendations.length }];
    }
    return [[]];
  };

  const req = {
    user: { id: 7 },
    body: {
      ...validBody,
      risk_percent: 45.0,
      risk_label: 'Sedang',
    },
  };
  const res = createMockRes();

  await submitScreening(req, res);

  assert.equal(res.statusCode, 201);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.id, 101);
  assert.equal(res.body.data.risk_percent, 45.0);
  assert.equal(res.body.data.risk_label, 'Sedang');
  assert.ok(savedRecommendations.length > 0);
});

test('screeningController.getScreeningHistory: tolak parameter pagination invalid (400)', async () => {
  const req = { user: { id: 1 }, query: { page: '0', limit: '500' } };
  const res = createMockRes();

  await getScreeningHistory(req, res);

  assert.equal(res.statusCode, 400);
});

test('screeningController.getScreeningHistory: kembalikan riwayat dengan metadata pagination', async () => {
  db.execute = async () => [[
    { id: 10, created_at: '2026-11-10', risk_percent: 15, risk_label: 'Rendah', bmi: 22.1 },
    { id: 9, created_at: '2026-11-09', risk_percent: 40, risk_label: 'Sedang', bmi: 26.0 },
    { id: 8, created_at: '2026-11-08', risk_percent: 70, risk_label: 'Tinggi', bmi: 31.2 }, // extra row for hasMore
  ]];

  const req = { user: { id: 1 }, query: { page: '1', limit: '2' } };
  const res = createMockRes();

  await getScreeningHistory(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.length, 2);
  assert.deepEqual(res.body.pagination, { page: 1, limit: 2, hasMore: true });
});

test('screeningController.getScreeningDetail: 400 jika ID tidak valid dan 404 jika tidak ditemukan', async () => {
  const reqInvalid = { user: { id: 1 }, params: { id: 'abc' } };
  const resInvalid = createMockRes();
  await getScreeningDetail(reqInvalid, resInvalid);
  assert.equal(resInvalid.statusCode, 400);

  db.execute = async () => [[]];
  const reqMissing = { user: { id: 1 }, params: { id: '999' } };
  const resMissing = createMockRes();
  await getScreeningDetail(reqMissing, resMissing);
  assert.equal(resMissing.statusCode, 404);
});

test('screeningController.getScreeningRecommendations: kembalikan daftar rekomendasi (200)', async () => {
  db.execute = async () => [[
    { id: 1, category: 'Pemeriksaan', title: 'Cek Gula Darah Berkala', description: 'Desk' },
  ]];

  const req = { user: { id: 1 }, params: { id: '10' } };
  const res = createMockRes();

  await getScreeningRecommendations(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.length, 1);
  assert.equal(res.body.data[0].category, 'Pemeriksaan');
});
