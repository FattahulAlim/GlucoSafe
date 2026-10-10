
const { z } = require('zod');

const binaryField = z.number().int().min(0).max(1);

const screeningSchema = z.object({
  sex: binaryField,
  age: z.number().int().min(1).max(13),

  height_cm: z.number().min(50).max(250),
  weight_kg: z.number().min(10).max(400),

  high_bp: binaryField,
  high_chol: binaryField,
  stroke: binaryField,
  heart_disease: binaryField,
  diff_walk: binaryField,
  smoker: binaryField,
  phys_activity: binaryField,
  fruits: binaryField,
  veggies: binaryField,

  gen_hlth: z.number().int().min(1).max(5),
  ment_hlth: z.number().int().min(0).max(30),
  phys_hlth: z.number().int().min(0).max(30),
}).strict();

module.exports = { screeningSchema };
