const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { mock } = require('node:test');
const db = require('../src/config/database');
const { uploadPhoto, deletePhoto, saveFcmToken } = require('../src/controllers/userController');

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

const originalExecute = db.execute;

test.beforeEach(() => {
  mock.method(console, 'error', () => {});
});

test.afterEach(() => {
  db.execute = originalExecute;
  mock.restoreAll();
});

function stubDb({ photoUrl = null, noUser = false, fail = false } = {}) {
  const calls = [];
  db.execute = async (sql, params) => {
    calls.push({ sql, params });
    if (fail) throw new Error('db down');
    if (sql.includes('SELECT photo_url FROM users')) {
      return [noUser ? [] : [{ photo_url: photoUrl }]];
    }
    return [{ affectedRows: 1 }];
  };
  return calls;
}

function stubFiles({ oldFileExists }) {
  const realExists = fs.existsSync;
  const removed = [];
  mock.method(fs, 'existsSync', (p) =>
    String(p).includes('lama.jpg') ? oldFileExists : realExists(p)
  );
  mock.method(fs, 'unlinkSync', (p) => {
    removed.push(String(p));
  });
  return removed;
}

const updateCall = (calls, fragment) => calls.find((c) => c.sql.includes(fragment));

// ───────────────────────── uploadPhoto ─────────────────────────

test('uploadPhoto: 400 jika tidak ada file yang diunggah', async () => {
  stubDb();
  const res = createMockRes();

  await uploadPhoto({ user: { id: 1 } }, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.success, false);
});

test('uploadPhoto: simpan alamat foto baru dan tidak menghapus apa pun jika belum punya foto', async () => {
  const calls = stubDb({ photoUrl: null });
  const removed = stubFiles({ oldFileExists: false });
  const res = createMockRes();

  await uploadPhoto({ user: { id: 1 }, file: { filename: 'baru.jpg' } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.photo_url, '/uploads/avatars/baru.jpg');
  assert.deepEqual(updateCall(calls, 'UPDATE users SET photo_url = ?').params, [
    '/uploads/avatars/baru.jpg',
    1,
  ]);
  assert.equal(removed.length, 0);
});

test('uploadPhoto: foto lama dihapus dari disk saat diganti', async () => {
  stubDb({ photoUrl: '/uploads/avatars/lama.jpg' });
  const removed = stubFiles({ oldFileExists: true });
  const res = createMockRes();

  await uploadPhoto({ user: { id: 1 }, file: { filename: 'baru.jpg' } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(removed.length, 1);
  assert.ok(removed[0].endsWith(path.join('uploads', 'avatars', 'lama.jpg')));
});

test('uploadPhoto: tetap berhasil jika file foto lama sudah tidak ada di disk', async () => {
  const calls = stubDb({ photoUrl: '/uploads/avatars/lama.jpg' });
  const removed = stubFiles({ oldFileExists: false });
  const res = createMockRes();

  await uploadPhoto({ user: { id: 1 }, file: { filename: 'baru.jpg' } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(removed.length, 0);
  assert.ok(updateCall(calls, 'UPDATE users SET photo_url = ?'));
});

test('uploadPhoto: 500 jika database gagal', async () => {
  stubDb({ fail: true });
  const res = createMockRes();

  await uploadPhoto({ user: { id: 1 }, file: { filename: 'baru.jpg' } }, res);

  assert.equal(res.statusCode, 500);
  assert.equal(res.body.success, false);
});

test(
  'uploadPhoto: 404 jika pengguna tidak ditemukan',
  { todo: 'Saat ini kode membaca users[0].photo_url dari daftar kosong, hasilnya 500, bukan 404' },
  async () => {
    stubDb({ noUser: true });
    const res = createMockRes();

    await uploadPhoto({ user: { id: 999 }, file: { filename: 'baru.jpg' } }, res);

    assert.equal(res.statusCode, 404);
  }
);

// ───────────────────────── deletePhoto ─────────────────────────

test('deletePhoto: hapus file dari disk dan kosongkan kolom foto', async () => {
  const calls = stubDb({ photoUrl: '/uploads/avatars/lama.jpg' });
  const removed = stubFiles({ oldFileExists: true });
  const res = createMockRes();

  await deletePhoto({ user: { id: 1 } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(removed.length, 1);
  assert.ok(removed[0].endsWith(path.join('uploads', 'avatars', 'lama.jpg')));
  assert.deepEqual(updateCall(calls, 'UPDATE users SET photo_url = NULL').params, [1]);
});

test('deletePhoto: 200 tanpa menyentuh disk dan database jika memang belum punya foto', async () => {
  const calls = stubDb({ photoUrl: null });
  const removed = stubFiles({ oldFileExists: false });
  const res = createMockRes();

  await deletePhoto({ user: { id: 1 } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.message, 'Foto profil berhasil dihapus.');
  assert.equal(removed.length, 0);
  assert.equal(updateCall(calls, 'UPDATE users SET photo_url = NULL'), undefined);
});

test('deletePhoto: 500 jika database gagal', async () => {
  stubDb({ fail: true });
  const res = createMockRes();

  await deletePhoto({ user: { id: 1 } }, res);

  assert.equal(res.statusCode, 500);
});

test(
  'deletePhoto: 404 jika pengguna tidak ditemukan',
  { todo: 'Saat ini kode membaca users[0].photo_url dari daftar kosong, hasilnya 500, bukan 404' },
  async () => {
    stubDb({ noUser: true });
    const res = createMockRes();

    await deletePhoto({ user: { id: 999 } }, res);

    assert.equal(res.statusCode, 404);
  }
);

// ───────────────────────── saveFcmToken ─────────────────────────

test('saveFcmToken: 400 jika token kosong atau bukan teks', async () => {
  const calls = stubDb();

  for (const body of [{}, { fcm_token: '' }, { fcm_token: '   ' }, { fcm_token: 123 }]) {
    const res = createMockRes();
    await saveFcmToken({ user: { id: 1 }, body }, res);
    assert.equal(res.statusCode, 400, JSON.stringify(body));
  }
  assert.equal(calls.length, 0, 'tidak boleh ada query ke database');
});

test('saveFcmToken: simpan token yang sudah dipangkas spasinya', async () => {
  const calls = stubDb();
  const res = createMockRes();

  await saveFcmToken({ user: { id: 7 }, body: { fcm_token: '  token-abc123  ' } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.deepEqual(updateCall(calls, 'UPDATE users SET fcm_token = ?').params, ['token-abc123', 7]);
});

test('saveFcmToken: 500 jika database gagal', async () => {
  stubDb({ fail: true });
  const res = createMockRes();

  await saveFcmToken({ user: { id: 1 }, body: { fcm_token: 'token-abc' } }, res);

  assert.equal(res.statusCode, 500);
  assert.equal(res.body.message, 'Gagal menyimpan FCM token.');
});