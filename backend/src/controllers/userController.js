
const db = require('../config/database');
const bcrypt = require('bcrypt');

async function getMe(req, res) {
  try {
    const [users] = await db.execute(
      `SELECT id, name, email, created_at
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan.',
      });
    }

    return res.json({
      success: true,
      message: 'Profil pengguna berhasil diambil.',
      data: users[0],
    });
  } catch (error) {
    console.error('Get profile error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

async function updateProfile(req, res) {
  try {
    const { name, email } = req.body;

    if (!name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Nama dan email wajib diisi.',
      });
    }

    // Cek apakah email sudah dipakai user lain
    const [existing] = await db.execute(
      `SELECT id FROM users WHERE email = ? AND id != ? LIMIT 1`,
      [email, req.user.id]
    );

    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email sudah terdaftar oleh pengguna lain.',
      });
    }

    await db.execute(
      `UPDATE users SET name = ?, email = ? WHERE id = ?`,
      [name, email, req.user.id]
    );

    const [updated] = await db.execute(
      `SELECT id, name, email, created_at FROM users WHERE id = ? LIMIT 1`,
      [req.user.id]
    );

    return res.json({
      success: true,
      message: 'Profil berhasil diperbarui.',
      data: updated[0],
    });
  } catch (error) {
    console.error('Update profile error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

async function changePassword(req, res) {
  try {
    const { currentPassword, newPassword, confirmNewPassword } = req.body;

    if (
      typeof currentPassword !== 'string' ||
      typeof newPassword !== 'string' ||
      typeof confirmNewPassword !== 'string' ||
      !currentPassword.trim() ||
      !newPassword.trim() ||
      !confirmNewPassword.trim()
    ) {
      return res.status(400).json({
        success: false,
        message: 'Kata sandi lama, kata sandi baru, dan konfirmasi kata sandi baru wajib diisi.',
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Kata sandi baru minimal 8 karakter.',
      });
    }

    if (newPassword !== confirmNewPassword) {
      return res.status(400).json({
        success: false,
        message: 'Kata sandi baru dan konfirmasi kata sandi baru tidak cocok.',
      });
    }

    const [users] = await db.execute(
      `SELECT id, password FROM users WHERE id = ? LIMIT 1`,
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan.',
      });
    }

    const user = users[0];
    const currentPasswordValid = await bcrypt.compare(currentPassword, user.password);

    if (!currentPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Kata sandi lama tidak sesuai.',
      });
    }

    const newPasswordHash = await bcrypt.hash(newPassword.trim(), 12);

    await db.execute(
      `UPDATE users SET password = ? WHERE id = ?`,
      [newPasswordHash, req.user.id]
    );

    return res.json({
      success: true,
      message: 'Kata sandi berhasil diperbarui.',
    });
  } catch (error) {
    console.error('Change password error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

module.exports = { getMe, updateProfile, changePassword };
