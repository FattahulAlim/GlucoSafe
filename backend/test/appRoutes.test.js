const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const request = require('supertest');
const { mock } = require('node:test');

process.env.JWT_SECRET = 'rahasia-khusus-test';

const db = require('../src/config/database');
const app = require('../src/app');

const originalExecute = db.execute;

test.beforeEach(() => {
  mock.method(console, 'error', () => {});
});

test.afterEach(() => {
  db.execute = originalExecute;
  mock.restoreAll();
});

const tokenFor = (userId = 7, secret = process.env.JWT_SECRET) =>
  jwt.sign({ userId }, secret, { expiresIn: '1h' });

const bearer = (token) => `Bearer ${token}`;

/** Database yang tidak boleh disentuh. Mencatat jika ada yang memanggil. */
function forbidDb() {
  const calls = [];
  db.execute = async (sql, params) => {
    calls.push({ sql, params });
    throw new Error('database tidak boleh dipanggil');
  };
  return calls;
}

// ───────────────────────── Rute publik ─────────────────────────

test('GET /api/health: 200 dan CORS terbuka', async () => {
  const res = await request(app).get('/api/health');

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.headers['access-control-allow-origin'], '*');
});

test('alamat yang tidak dikenal dibalas 404', async () => {
  const res = await request(app).get('/api/tidak-ada');

  assert.equal(res.status, 404);
});

test('POST /api/auth/register: 400 untuk isian kosong tanpa menyentuh database', async () => {
  const calls = forbidDb();
  const res = await request(app).post('/api/auth/register').send({});

  assert.equal(res.status, 400);
  assert.equal(calls.length, 0);
});

test('POST /api/auth/login: 400 untuk isian kosong tanpa menyentuh database', async () => {
  const calls = forbidDb();
  const res = await request(app).post('/api/auth/login').send({});

  assert.equal(res.status, 400);
  assert.equal(calls.length, 0);
});

// ───────────────────────── Perlindungan token ─────────────────────────

const protectedRoutes = [
  ['get', '/api/users/me'],
  ['put', '/api/users/me'],
  ['patch', '/api/users/me/password'],
  ['put', '/api/users/me/photo'],
  ['delete', '/api/users/me/photo'],
  ['post', '/api/users/fcm-token'],
  ['post', '/api/screenings'],
  ['get', '/api/screenings'],
  ['get', '/api/screenings/1'],
  ['get', '/api/screenings/1/recommendations'],
];

test('semua rute yang dilindungi menolak permintaan tanpa token (401)', async () => {
  const calls = forbidDb();

  for (const [method, url] of protectedRoutes) {
    const res = await request(app)[method](url);

    assert.equal(res.status, 401, `${method.toUpperCase()} ${url}`);
    assert.equal(res.body.success, false, `${method.toUpperCase()} ${url}`);
    assert.equal(res.body.message, 'Token autentikasi diperlukan.');
  }
  assert.equal(calls.length, 0, 'database tidak boleh dipanggil tanpa token');
});

test('token: header tanpa kata Bearer ditolak (401)', async () => {
  const res = await request(app)
    .get('/api/users/me')
    .set('Authorization', `Token ${tokenFor()}`);

  assert.equal(res.status, 401);
  assert.equal(res.body.message, 'Token autentikasi diperlukan.');
});

test('token: teks asal-asalan ditolak (401)', async () => {
  const calls = forbidDb();
  const res = await request(app).get('/api/users/me').set('Authorization', 'Bearer bukan-jwt');

  assert.equal(res.status, 401);
  assert.equal(res.body.message, 'Token tidak valid atau sudah kedaluwarsa.');
  assert.equal(calls.length, 0);
});

test('token: ditandatangani dengan kunci lain ditolak (401)', async () => {
  const forged = tokenFor(7, 'kunci-palsu');
  const res = await request(app).get('/api/users/me').set('Authorization', bearer(forged));

  assert.equal(res.status, 401);
  assert.equal(res.body.message, 'Token tidak valid atau sudah kedaluwarsa.');
});

test('token: yang sudah kedaluwarsa ditolak (401)', async () => {
  const expired = jwt.sign(
    { userId: 7, exp: Math.floor(Date.now() / 1000) - 60 },
    process.env.JWT_SECRET
  );
  const res = await request(app).get('/api/users/me').set('Authorization', bearer(expired));

  assert.equal(res.status, 401);
  assert.equal(res.body.message, 'Token tidak valid atau sudah kedaluwarsa.');
});

test('token valid: id pengguna dari token dipakai untuk query ke database', async () => {
  const calls = [];
  db.execute = async (sql, params) => {
    calls.push({ sql, params });
    return [[{ id: 7, name: 'Siti', email: 'siti@example.com', photo_url: null, created_at: '2026-01-01' }]];
  };

  const res = await request(app).get('/api/users/me').set('Authorization', bearer(tokenFor(7)));

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.name, 'Siti');
  assert.deepEqual(calls[0].params, [7]);
});

// ───────────────────────── Unggah foto profil ─────────────────────────

const avatarDir = path.join(process.cwd(), 'uploads', 'avatars');
const countAvatarFiles = () => fs.readdirSync(avatarDir).length;

const tinyPng = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==',
  'base64'
);

test('PUT /api/users/me/photo: 400 jika tidak ada file', async () => {
  const calls = forbidDb();
  const res = await request(app).put('/api/users/me/photo').set('Authorization', bearer(tokenFor()));

  assert.equal(res.status, 400);
  assert.equal(calls.length, 0);
});

test('PUT /api/users/me/photo: gambar sah diterima dan disimpan', async () => {
  const calls = [];
  db.execute = async (sql, params) => {
    calls.push({ sql, params });
    if (sql.includes('SELECT photo_url FROM users')) return [[{ photo_url: null }]];
    return [{ affectedRows: 1 }];
  };

  const res = await request(app)
    .put('/api/users/me/photo')
    .set('Authorization', bearer(tokenFor(7)))
    .attach('photo', tinyPng, { filename: 'foto.png', contentType: 'image/png' });

  const savedFile = res.body.data && path.join(process.cwd(), res.body.data.photo_url);
  try {
    assert.equal(res.status, 200);
    assert.match(res.body.data.photo_url, /^\/uploads\/avatars\/avatar-7-\d+-\d+\.png$/);
    assert.ok(fs.existsSync(savedFile), 'file harus tersimpan di disk');
  } finally {
    if (savedFile && fs.existsSync(savedFile)) fs.unlinkSync(savedFile); // bersihkan
  }
});

test('PUT /api/users/me/photo: file bukan gambar ditolak dan tidak disimpan', async () => {
  const calls = forbidDb();
  const before = countAvatarFiles();

  const res = await request(app)
    .put('/api/users/me/photo')
    .set('Authorization', bearer(tokenFor()))
    .attach('photo', Buffer.from('ini bukan gambar'), { filename: 'catatan.txt', contentType: 'text/plain' });

  assert.ok(res.status >= 400, `status ${res.status}`);
  assert.equal(countAvatarFiles(), before, 'tidak boleh ada file baru');
  assert.equal(calls.length, 0);
});

test('PUT /api/users/me/photo: file lebih dari 2 MB ditolak dan tidak disimpan', async () => {
  const calls = forbidDb();
  const before = countAvatarFiles();

  const res = await request(app)
    .put('/api/users/me/photo')
    .set('Authorization', bearer(tokenFor()))
    .attach('photo', Buffer.alloc(2 * 1024 * 1024 + 1), { filename: 'besar.png', contentType: 'image/png' });

  assert.ok(res.status >= 400, `status ${res.status}`);
  assert.equal(countAvatarFiles(), before, 'tidak boleh ada file baru');
  assert.equal(calls.length, 0);
});

test(
  'PUT /api/users/me/photo: unggahan tidak valid dibalas 4xx, bukan 500',
  { todo: 'Tidak ada error handler Express, jadi kesalahan multer berakhir sebagai 500' },
  async () => {
    forbidDb();
    const cases = [
      { filename: 'catatan.txt', contentType: 'text/plain', data: Buffer.from('bukan gambar') },
      { filename: 'besar.png', contentType: 'image/png', data: Buffer.alloc(2 * 1024 * 1024 + 1) },
    ];

    for (const c of cases) {
      const res = await request(app)
        .put('/api/users/me/photo')
        .set('Authorization', bearer(tokenFor()))
        .attach('photo', c.data, { filename: c.filename, contentType: c.contentType });

      assert.ok(res.status >= 400 && res.status < 500, `${c.filename}: status ${res.status}`);
    }
  }
);