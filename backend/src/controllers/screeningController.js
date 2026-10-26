
const db = require('../config/database');
const { screeningSchema } = require('../validators/screeningValidator');
const { calculateBmi, generateRecommendations } = require('../services/screeningService');
const { predictDiabetesRisk } = require('../services/mlService');

async function submitScreening(req, res) {
  try {
    // 1. Validasi input dengan Zod
    const parsed = screeningSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        success: false,
        message: 'Data skrining tidak valid.',
        errors: parsed.error.flatten().fieldErrors,
      });
    }

    const form = parsed.data;

    // 2. Hitung BMI di backend (jangan percaya nilai dari client)
    const bmi = calculateBmi(form.height_cm, form.weight_kg);

    // 3. Siapkan fitur untuk ML API (nama key sesuai kontrak ML)
    const mlFeatures = {
      HighBP: form.high_bp,
      HighChol: form.high_chol,
      BMI: bmi,
      Smoker: form.smoker,
      Stroke: form.stroke,
      HeartDiseaseorAttack: form.heart_disease,
      PhysActivity: form.phys_activity,
      Fruits: form.fruits,
      Veggies: form.veggies,
      GenHlth: form.gen_hlth,
      MentHlth: form.ment_hlth,
      PhysHlth: form.phys_hlth,
      DiffWalk: form.diff_walk,
      Sex: form.sex,
      Age: form.age,
    };

    // 4. Panggil ML API
    const prediction = await predictDiabetesRisk(mlFeatures);
    const { risk_percent, risk_label } = prediction;

    // 5. Simpan ke screening_results
    const [insertResult] = await db.execute(
      `INSERT INTO screening_results (
        user_id, risk_percent, risk_label,
        sex, age, height_cm, weight_kg, bmi,
        high_bp, high_chol, stroke, heart_disease, diff_walk,
        smoker, phys_activity, fruits, veggies,
        gen_hlth, ment_hlth, phys_hlth
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id, risk_percent, risk_label,
        form.sex, form.age, form.height_cm, form.weight_kg, bmi,
        form.high_bp, form.high_chol, form.stroke, form.heart_disease, form.diff_walk,
        form.smoker, form.phys_activity, form.fruits, form.veggies,
        form.gen_hlth, form.ment_hlth, form.phys_hlth,
      ]
    );

    const screeningId = insertResult.insertId;

    // 6. Generate dan simpan rekomendasi
    const recommendations = generateRecommendations(form, risk_label, bmi);

    if (recommendations.length > 0) {
      const recValues = recommendations.map(r => [screeningId, r.category, r.title, r.description]);
      await db.query(
        'INSERT INTO recommendations (result_id, category, title, description) VALUES ?',
        [recValues]
      );
    }

    // 7. Ambil created_at dari DB untuk konsistensi
    const [[screening]] = await db.execute(
      'SELECT id, created_at FROM screening_results WHERE id = ? LIMIT 1',
      [screeningId]
    );

    // 8. Return hasil lengkap
    return res.status(201).json({
      success: true,
      message: 'Skrining berhasil disimpan.',
      data: {
        id: screeningId,
        created_at: screening.created_at,
        risk_percent,
        risk_label,
        bmi,
        recommendations,
      },
    });
  } catch (error) {
    console.error('Submit screening error:', error.message);

    // Bedakan error ML API vs error internal
    if (error.message.includes('ML API') || error.message.includes('ML_API_URL')) {
      return res.status(502).json({
        success: false,
        message: 'Layanan prediksi tidak tersedia saat ini. Coba beberapa saat lagi.',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server.',
    });
  }
}

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
  submitScreening,
  getScreeningHistory,
  getScreeningDetail,
  getScreeningRecommendations,
};
