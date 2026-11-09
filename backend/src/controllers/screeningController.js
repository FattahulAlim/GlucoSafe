
const db = require('../config/database');

async function getScreeningHistory(req, res) {
  try {
    const hasPagination = req.query.page !== undefined || req.query.limit !== undefined;
    let page;
    let limit;

    if (hasPagination) {
      page = req.query.page === undefined ? 1 : Number(req.query.page);
      limit = req.query.limit === undefined ? 20 : Number(req.query.limit);

      if (
        !Number.isSafeInteger(page) ||
        page < 1 ||
        !Number.isSafeInteger(limit) ||
        limit < 1 ||
        limit > 100
      ) {
        return res.status(400).json({
          success: false,
          message: 'Parameter page harus >= 1 dan limit harus antara 1-100.',
        });
      }
    }

    const offset = hasPagination ? (page - 1) * limit : 0;
    if (hasPagination && !Number.isSafeInteger(offset)) {
      return res.status(400).json({
        success: false,
        message: 'Nilai offset pagination terlalu besar.',
      });
    }

    const paginationSql = hasPagination ? 'LIMIT ? OFFSET ?' : '';
    const paginationParams = hasPagination ? [limit + 1, offset] : [];
    const [results] = await db.execute(
      `SELECT
         id,
         created_at,
         risk_percent AS risk_percentage,
         risk_label AS risk_level,
         bmi
       FROM screening_results
       WHERE user_id = ?
       ORDER BY created_at DESC, id DESC
       ${paginationSql}`,
      [req.user.id, ...paginationParams]
    );
    const hasMore = hasPagination && results.length > limit;
    if (hasMore) results.pop();

    return res.json({
      success: true,
      message: 'Riwayat screening berhasil diambil.',
      data: results,
      ...(hasPagination
        ? {
            pagination: {
              page,
              limit,
              hasMore,
            },
          }
        : {}),
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
