const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware'); 
const { getMe, updateProfile, changePassword, uploadPhoto, deletePhoto, saveFcmToken } = require('../controllers/userController');

router.get('/me', authMiddleware, getMe);
router.put('/me', authMiddleware, updateProfile);
router.patch('/me/password', authMiddleware, changePassword);
router.put('/me/photo', authMiddleware, upload.single('photo'), uploadPhoto); 
router.delete('/me/photo', authMiddleware, deletePhoto); 
router.post('/fcm-token', authMiddleware, saveFcmToken);

module.exports = router;