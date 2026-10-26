
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');

const {
  submitScreening,
  getScreeningHistory,
  getScreeningDetail,
  getScreeningRecommendations,
} = require('../controllers/screeningController');

router.post('/', authMiddleware, submitScreening);
router.get('/', authMiddleware, getScreeningHistory);
router.get('/:id/recommendations', authMiddleware, getScreeningRecommendations);
router.get('/:id', authMiddleware, getScreeningDetail);

module.exports = router;
