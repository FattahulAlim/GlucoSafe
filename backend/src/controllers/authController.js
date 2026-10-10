
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

async function register(req, res) {
  try {
    const { name, email, password } = req.body;

    if (
      typeof name !== 'string' ||
      !name.trim() ||
      typeof email !== 'string' ||
      !email.trim() ||
      typeof password !== 'string' ||
      password.length < 8
    ) {
      return res.status(400).json({
        success: false,
        message: 'Nama, email, dan password minimal 8 karakter wajib diisi dengan benar.',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const [existing] = await db.execute(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [normalizedEmail]
    );

    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email sudah terdaftar.',
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const [result] = await db.execute(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name.trim(), normalizedEmail, passwordHash]
    );

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil.',
      data: {
        id: result.insertId,
        name: name.trim(),
        email: normalizedEmail,
      },
    });
  } catch (error) {
    console.error('Register error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (
      typeof email !== 'string' ||
      typeof password !== 'string' ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.',
      });
    }

    const [users] = await db.execute(
      'SELECT id, name, email, password FROM users WHERE email = ? LIMIT 1',
      [email.trim().toLowerCase()]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.',
      });
    }

    const user = users[0];
    const passwordValid = await bcrypt.compare(password, user.password);

    if (!passwordValid) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.',
      });
    }

    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET belum dikonfigurasi.');
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.json({
      success: true,
      message: 'Login berhasil.',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
        },
      },
    });
  } catch (error) {
    console.error('Login error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

module.exports = { register, login };
