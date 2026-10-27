
const db = require('../config/database');

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

module.exports = { getMe, updateProfile };
