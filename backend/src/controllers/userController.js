
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

module.exports = { getMe };
