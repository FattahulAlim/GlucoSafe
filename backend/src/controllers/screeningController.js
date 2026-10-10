
const db = require('../config/database');

async function getScreeningHistory(req, res) {
  try {
    const [results] = await db.execute(
      `SELECT
         id,
         created_at,
         risk_percent,
         risk_label,
         bmi
       FROM screening_results
       WHERE user_id = ?
       ORDER BY created_at DESC, id DESC`,
      [req.user.id]
    );

    return res.json({
      success: true,
      message: 'Riwayat screening berhasil diambil.',
      data: results,
    });
  } catch (error) {
    console.error('Screening history error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

async function getScreeningDetail(req, res) {
  try {
    const id = Number(req.params.id);

    if (!Number.isSafeInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID screening tidak valid.',
      });
    }

    const [results] = await db.execute(
      `SELECT *
       FROM screening_results
       WHERE id = ? AND user_id = ?
       LIMIT 1`,
      [id, req.user.id]
    );

    if (results.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Hasil screening tidak ditemukan.',
      });
    }

    return res.json({
      success: true,
      message: 'Detail screening berhasil diambil.',
      data: results[0],
    });
  } catch (error) {
    console.error('Screening detail error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

async function getScreeningRecommendations(req, res) {
  try {
    const id = Number(req.params.id);

    if (!Number.isSafeInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID screening tidak valid.',
      });
    }

    const [results] = await db.execute(
      `SELECT r.id, r.category, r.title, r.description
       FROM recommendations r
       INNER JOIN screening_results s ON s.id = r.result_id
       WHERE s.id = ? AND s.user_id = ?
       ORDER BY r.id ASC`,
      [id, req.user.id]
    );

    return res.json({
      success: true,
      message: 'Rekomendasi berhasil diambil.',
      data: results,
    });
  } catch (error) {
    console.error('Recommendations error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

module.exports = {
  getScreeningHistory,
  getScreeningDetail,
  getScreeningRecommendations,
};
