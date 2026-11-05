
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const { getMe, updateProfile, changePassword } = require('../controllers/userController');

router.get('/me', authMiddleware, getMe);
router.put('/me', authMiddleware, updateProfile);
router.patch('/me/password', authMiddleware, changePassword);

module.exports = router;
