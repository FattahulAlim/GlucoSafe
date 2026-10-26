
function calculateBmi(heightCm, weightKg) {
  const heightM = heightCm / 100;
  return Number((weightKg / (heightM * heightM)).toFixed(1));
}

module.exports = { calculateBmi };
