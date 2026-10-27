
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { getMe, updateProfile } = require('../controllers/userController');

router.get('/me', authMiddleware, getMe);
router.put('/me', authMiddleware, updateProfile);

module.exports = router;
