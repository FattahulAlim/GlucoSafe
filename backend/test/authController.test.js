const test = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const { register, login } = require('../src/controllers/authController');

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
const originalJwtSecret = process.env.JWT_SECRET;

test.beforeEach(() => {
  process.env.JWT_SECRET = 'test_secret_for_auth_123';
});

test.afterEach(() => {
  db.execute = originalExecute;
  if (originalJwtSecret === undefined) delete process.env.JWT_SECRET;
  else process.env.JWT_SECRET = originalJwtSecret;
});

test('authController.register: tolak input tidak valid (400)', async () => {
  const req = { body: { name: '', email: 'notanemail', password: '123' } };
  const res = createMockRes();

  await register(req, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.success, false);
});

test('authController.register: tolak jika email sudah terdaftar (409)', async () => {
  db.execute = async (sql) => {
    if (sql.includes('SELECT id FROM users')) {
      return [[{ id: 1 }]]; // email found
    }
    return [[]];
  };

  const req = {
    body: { name: 'User Test', email: 'exist@example.com', password: 'Password123!' },
  };
  const res = createMockRes();

  await register(req, res);

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.message, 'Email sudah terdaftar.');
});

test('authController.register: berhasil registrasi akun baru (201)', async () => {
  db.execute = async (sql) => {
    if (sql.includes('SELECT id FROM users')) {
      return [[]]; // email not taken
    }
    if (sql.includes('INSERT INTO users')) {
      return [{ insertId: 99 }];
    }
    return [[]];
  };

  const req = {
    body: { name: 'User Baru', email: 'baru@example.com', password: 'Password123!' },
  };
  const res = createMockRes();

  await register(req, res);

  assert.equal(res.statusCode, 201);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.id, 99);
  assert.equal(res.body.data.email, 'baru@example.com');
});

test('authController.login: tolak input kosong (400)', async () => {
  const req = { body: { email: '', password: '' } };
  const res = createMockRes();

  await login(req, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.success, false);
});

test('authController.login: tolak jika email tidak terdaftar (401)', async () => {
  db.execute = async () => [[]]; // user not found

  const req = { body: { email: 'unknown@example.com', password: 'Password123!' } };
  const res = createMockRes();

  await login(req, res);

  assert.equal(res.statusCode, 401);
  assert.equal(res.body.message, 'Email atau password salah.');
});

test('authController.login: tolak jika password keliru (401)', async () => {
  const hashedPassword = await bcrypt.hash('CorrectPassword123!', 10);
  db.execute = async () => [[{ id: 1, name: 'User', email: 'test@example.com', password: hashedPassword }]];

  const req = { body: { email: 'test@example.com', password: 'WrongPassword!' } };
  const res = createMockRes();

  await login(req, res);

  assert.equal(res.statusCode, 401);
  assert.equal(res.body.message, 'Email atau password salah.');
});

test('authController.login: berhasil login dan kembalikan token jwt (200)', async () => {
  const plainPassword = 'CorrectPassword123!';
  const hashedPassword = await bcrypt.hash(plainPassword, 10);
  db.execute = async () => [[{ id: 42, name: 'Budi', email: 'budi@example.com', password: hashedPassword }]];

  const req = { body: { email: 'budi@example.com', password: plainPassword } };
  const res = createMockRes();

  await login(req, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.user.id, 42);
  assert.ok(typeof res.body.data.token === 'string');

  const decoded = jwt.verify(res.body.data.token, process.env.JWT_SECRET);
  assert.equal(decoded.userId, 42);
});
