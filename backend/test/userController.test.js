const test = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const db = require('../src/config/database');
const { getMe, updateProfile, changePassword } = require('../src/controllers/userController');

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

test.afterEach(() => {
  db.execute = originalExecute;
});

test('userController.getMe: 404 jika user tidak ditemukan', async () => {
  db.execute = async () => [[]];
  const req = { user: { id: 999 } };
  const res = createMockRes();

  await getMe(req, res);

  assert.equal(res.statusCode, 404);
  assert.equal(res.body.success, false);
});

test('userController.getMe: 200 kembalikan profil user', async () => {
  db.execute = async () => [[{ id: 1, name: 'Siti', email: 'siti@example.com', created_at: '2026-01-01' }]];
  const req = { user: { id: 1 } };
  const res = createMockRes();

  await getMe(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.name, 'Siti');
});

test('userController.updateProfile: 400 jika nama atau email kosong', async () => {
  const req = { user: { id: 1 }, body: { name: '', email: '' } };
  const res = createMockRes();

  await updateProfile(req, res);

  assert.equal(res.statusCode, 400);
});

test('userController.updateProfile: 409 jika email dipakai pengguna lain', async () => {
  db.execute = async (sql) => {
    if (sql.includes('SELECT id FROM users WHERE email = ? AND id != ?')) {
      return [[{ id: 2 }]]; // duplicate found
    }
    return [[]];
  };

  const req = { user: { id: 1 }, body: { name: 'Siti Baru', email: 'taken@example.com' } };
  const res = createMockRes();

  await updateProfile(req, res);

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.message, 'Email sudah terdaftar oleh pengguna lain.');
});

test('userController.updateProfile: 200 berhasil update profil', async () => {
  db.execute = async (sql) => {
    if (sql.includes('SELECT id FROM users WHERE email = ? AND id != ?')) {
      return [[]]; // email available
    }
    if (sql.includes('UPDATE users SET')) {
      return [{ affectedRows: 1 }];
    }
    if (sql.includes('SELECT id, name, email, created_at FROM users')) {
      return [[{ id: 1, name: 'Siti Baru', email: 'siti_baru@example.com', created_at: '2026-01-01' }]];
    }
    return [[]];
  };

  const req = { user: { id: 1 }, body: { name: 'Siti Baru', email: 'siti_baru@example.com' } };
  const res = createMockRes();

  await updateProfile(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.name, 'Siti Baru');
});

test('userController.changePassword: 400 jika password baru kurang dari 8 karakter', async () => {
  const req = {
    user: { id: 1 },
    body: { currentPassword: 'OldPassword123!', newPassword: 'short', confirmNewPassword: 'short' },
  };
  const res = createMockRes();

  await changePassword(req, res);

  assert.equal(res.statusCode, 400);
  assert.match(res.body.message, /minimal 8 karakter/);
});

test('userController.changePassword: 400 jika konfirmasi password tidak cocok', async () => {
  const req = {
    user: { id: 1 },
    body: { currentPassword: 'OldPassword123!', newPassword: 'NewPassword123!', confirmNewPassword: 'MismatchPassword!' },
  };
  const res = createMockRes();

  await changePassword(req, res);

  assert.equal(res.statusCode, 400);
  assert.match(res.body.message, /tidak cocok/);
});

test('userController.changePassword: 401 jika kata sandi lama salah', async () => {
  const oldHashed = await bcrypt.hash('CorrectOld123!', 10);
  db.execute = async (sql) => {
    if (sql.includes('SELECT id, password FROM users')) {
      return [[{ id: 1, password: oldHashed }]];
    }
    return [[]];
  };

  const req = {
    user: { id: 1 },
    body: { currentPassword: 'WrongOldPassword!', newPassword: 'NewPassword123!', confirmNewPassword: 'NewPassword123!' },
  };
  const res = createMockRes();

  await changePassword(req, res);

  assert.equal(res.statusCode, 401);
  assert.equal(res.body.message, 'Kata sandi lama tidak sesuai.');
});

test('userController.changePassword: 200 berhasil perbarui password', async () => {
  const oldHashed = await bcrypt.hash('CorrectOld123!', 10);
  let updatedHash = null;
  db.execute = async (sql, params) => {
    if (sql.includes('SELECT id, password FROM users')) {
      return [[{ id: 1, password: oldHashed }]];
    }
    if (sql.includes('UPDATE users SET password = ?')) {
      updatedHash = params[0];
      return [{ affectedRows: 1 }];
    }
    return [[]];
  };

  const req = {
    user: { id: 1 },
    body: { currentPassword: 'CorrectOld123!', newPassword: 'BrandNewPassword123!', confirmNewPassword: 'BrandNewPassword123!' },
  };
  const res = createMockRes();

  await changePassword(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.ok(updatedHash);
  const isValid = await bcrypt.compare('BrandNewPassword123!', updatedHash);
  assert.equal(isValid, true);
});
