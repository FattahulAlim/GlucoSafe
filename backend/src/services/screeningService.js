
function calculateBmi(heightCm, weightKg) {
  const heightM = heightCm / 100;
  return Number((weightKg / (heightM * heightM)).toFixed(1));
}

/**
 * Generate rekomendasi otomatis berdasarkan hasil skrining.
 * @param {object} form  - field dari request (snake_case)
 * @param {string} riskLabel - 'Rendah' | 'Sedang' | 'Tinggi'
 * @param {number} bmi
 * @returns {Array<{category, title, description}>}
 */
function generateRecommendations(form, riskLabel, bmi) {
  const recs = [];

  // ── Pemeriksaan (berdasarkan risk level) ─────────────────────────────────
  if (riskLabel === 'Tinggi') {
    recs.push({
      category: 'Pemeriksaan',
      title: 'Segera Konsultasi ke Dokter',
      description:
        'Risiko Anda tergolong tinggi. Segera konsultasikan kondisi kesehatan Anda ke dokter atau fasilitas kesehatan terdekat untuk pemeriksaan gula darah lebih lanjut.',
    });
  } else if (riskLabel === 'Sedang') {
    recs.push({
      category: 'Pemeriksaan',
      title: 'Tes Gula Darah dalam 1 Bulan',
      description:
        'Risiko Anda tergolong sedang. Lakukan pemeriksaan gula darah dalam 1 bulan ke depan dan pantau perubahan gaya hidup Anda.',
    });
  } else {
    recs.push({
      category: 'Pemeriksaan',
      title: 'Cek Gula Darah Berkala',
      description:
        'Lakukan pemeriksaan gula darah minimal sekali setahun meski belum ada gejala untuk memantau kesehatan Anda.',
    });
  }

  // ── Aktivitas Fisik ───────────────────────────────────────────────────────
  if (form.phys_activity === 0) {
    recs.push({
      category: 'Aktivitas Fisik',
      title: 'Mulai Olahraga Ringan 30 Menit/Hari',
      description:
        'Anda belum aktif berolahraga. Mulailah dengan aktivitas ringan seperti jalan cepat selama 30 menit per hari, minimal 5 hari seminggu untuk menurunkan risiko diabetes.',
    });
  } else {
    recs.push({
      category: 'Aktivitas Fisik',
      title: 'Pertahankan Kebiasaan Olahraga',
      description:
        'Bagus! Terus pertahankan kebiasaan aktif berolahraga Anda. Variasikan jenis olahraga untuk menjaga motivasi dan manfaat yang optimal.',
    });
  }

  // ── Nutrisi ───────────────────────────────────────────────────────────────
  if (form.fruits === 0 || form.veggies === 0) {
    recs.push({
      category: 'Nutrisi',
      title: 'Perbanyak Buah & Sayuran',
      description:
        'Konsumsi buah dan sayuran Anda masih kurang. Targetkan minimal 5 porsi buah dan sayuran setiap hari untuk menjaga kadar gula darah dan meningkatkan asupan serat.',
    });
  } else {
    recs.push({
      category: 'Nutrisi',
      title: 'Pertahankan Pola Makan Sehat',
      description:
        'Hebat! Kebiasaan mengonsumsi buah dan sayuran sudah baik. Kurangi asupan gula tambahan dan makanan olahan untuk hasil yang lebih optimal.',
    });
  }

  // ── Kondisional: muncul hanya jika ada faktor risiko tambahan ─────────────
  if (form.smoker === 1) {
    recs.push({
      category: 'Gaya Hidup',
      title: 'Pertimbangkan Berhenti Merokok',
      description:
        'Merokok meningkatkan resistensi insulin dan risiko diabetes. Konsultasikan program berhenti merokok dengan tenaga kesehatan untuk mendapat dukungan yang tepat.',
    });
  }

  if (form.high_bp === 1) {
    recs.push({
      category: 'Kesehatan',
      title: 'Pantau Tekanan Darah Secara Berkala',
      description:
        'Tekanan darah tinggi berkaitan erat dengan risiko diabetes. Pantau tekanan darah minimal seminggu sekali dan batasi konsumsi garam.',
    });
  }

  if (form.high_chol === 1) {
    recs.push({
      category: 'Kesehatan',
      title: 'Kendalikan Kadar Kolesterol',
      description:
        'Kolesterol tinggi meningkatkan risiko komplikasi diabetes. Kurangi makanan berlemak jenuh dan perbanyak konsumsi ikan, kacang-kacangan, dan serat.',
    });
  }

  if (bmi > 27.5) {
    recs.push({
      category: 'Nutrisi',
      title: 'Konsultasi Gizi untuk Berat Badan Ideal',
      description:
        'BMI Anda melebihi batas normal untuk populasi Asia. Konsultasikan dengan ahli gizi untuk program penurunan berat badan yang sehat dan berkelanjutan.',
    });
  }

  return recs;
}

module.exports = { calculateBmi, generateRecommendations };
