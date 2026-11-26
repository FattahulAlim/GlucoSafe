const test = require('node:test');
const assert = require('node:assert/strict');
const { calculateBmi, generateRecommendations } = require('../src/services/screeningService');

const healthyForm = {
  phys_activity: 1,
  fruits: 1,
  veggies: 1,
  smoker: 0,
  high_bp: 0,
  high_chol: 0,
};

const titlesOf = (recs) => recs.map((r) => r.title);

test('calculateBmi: 168 cm dan 70 kg bernilai 24.8', () => {
  assert.equal(calculateBmi(168, 70), 24.8);
});

test('calculateBmi: dibulatkan ke satu desimal', () => {
  assert.equal(calculateBmi(170, 80), 27.7);
  assert.equal(calculateBmi(165, 63), 23.1);
});

test('generateRecommendations: pengguna sehat mendapat tiga rekomendasi dasar', () => {
  const recs = generateRecommendations(healthyForm, 'Rendah', 22);

  assert.deepEqual(titlesOf(recs), [
    'Cek Gula Darah Berkala',
    'Pertahankan Kebiasaan Olahraga',
    'Pertahankan Pola Makan Sehat',
  ]);
  assert.deepEqual(
    recs.map((r) => r.category),
    ['Pemeriksaan', 'Aktivitas Fisik', 'Nutrisi']
  );
});

test('generateRecommendations: judul pemeriksaan mengikuti tingkat risiko', () => {
  const titleByLabel = {
    Tinggi: 'Segera Konsultasi ke Dokter',
    Sedang: 'Tes Gula Darah dalam 1 Bulan',
    Rendah: 'Cek Gula Darah Berkala',
  };

  for (const [label, title] of Object.entries(titleByLabel)) {
    const recs = generateRecommendations(healthyForm, label, 22);
    assert.equal(recs[0].category, 'Pemeriksaan');
    assert.equal(recs[0].title, title, `risiko ${label}`);
  }
});

test('generateRecommendations: belum aktif berolahraga', () => {
  const recs = generateRecommendations({ ...healthyForm, phys_activity: 0 }, 'Rendah', 22);

  assert.ok(titlesOf(recs).includes('Mulai Olahraga Ringan 30 Menit/Hari'));
  assert.ok(!titlesOf(recs).includes('Pertahankan Kebiasaan Olahraga'));
});

test('generateRecommendations: kurang buah atau kurang sayur', () => {
  const patches = [{ fruits: 0 }, { veggies: 0 }, { fruits: 0, veggies: 0 }];

  for (const patch of patches) {
    const recs = generateRecommendations({ ...healthyForm, ...patch }, 'Rendah', 22);
    assert.ok(titlesOf(recs).includes('Perbanyak Buah & Sayuran'), JSON.stringify(patch));
    assert.ok(!titlesOf(recs).includes('Pertahankan Pola Makan Sehat'), JSON.stringify(patch));
  }
});

test('generateRecommendations: faktor risiko tambahan (rokok, tekanan darah, kolesterol)', () => {
  const cases = [
    [{ smoker: 1 }, 'Pertimbangkan Berhenti Merokok', 'Gaya Hidup'],
    [{ high_bp: 1 }, 'Pantau Tekanan Darah Secara Berkala', 'Kesehatan'],
    [{ high_chol: 1 }, 'Kendalikan Kadar Kolesterol', 'Kesehatan'],
  ];

  for (const [patch, title, category] of cases) {
    const recs = generateRecommendations({ ...healthyForm, ...patch }, 'Rendah', 22);
    const found = recs.find((r) => r.title === title);

    assert.ok(found, title);
    assert.equal(found.category, category);
    assert.equal(recs.length, 4); // 3 dasar + 1 tambahan
  }
});

test('generateRecommendations: BMI di atas 27.5 menambah konsultasi gizi, tepat 27.5 tidak', () => {
  const title = 'Konsultasi Gizi untuk Berat Badan Ideal';

  assert.ok(titlesOf(generateRecommendations(healthyForm, 'Rendah', 27.6)).includes(title));
  assert.ok(!titlesOf(generateRecommendations(healthyForm, 'Rendah', 27.5)).includes(title));
});

test('generateRecommendations: semua faktor risiko sekaligus menghasilkan tujuh rekomendasi lengkap', () => {
  const form = { phys_activity: 0, fruits: 0, veggies: 0, smoker: 1, high_bp: 1, high_chol: 1 };
  const recs = generateRecommendations(form, 'Tinggi', 30);

  assert.equal(recs.length, 7);
  for (const rec of recs) {
    assert.ok(rec.category && rec.title && rec.description, 'setiap rekomendasi harus lengkap');
  }
});