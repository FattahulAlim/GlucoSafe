
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
  submitScreening,
  predictScreening,
  getScreeningHistory,
  getScreeningDetail,
  getScreeningRecommendations,
} = require('../controllers/screeningController');

router.post('/predict', authMiddleware, predictScreening);
router.post('/', authMiddleware, submitScreening);
router.get('/history', authMiddleware, getScreeningHistory);
router.get('/', authMiddleware, getScreeningHistory);
router.get('/:id/recommendations', authMiddleware, getScreeningRecommendations);
router.get('/:id', authMiddleware, getScreeningDetail);

module.exports = router;
