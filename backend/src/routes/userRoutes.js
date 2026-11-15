const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware'); 
const { getMe, updateProfile, changePassword, uploadPhoto, deletePhoto } = require('../controllers/userController');

router.get('/me', authMiddleware, getMe);
router.put('/me', authMiddleware, updateProfile);
router.patch('/me/password', authMiddleware, changePassword);
router.put('/me/photo', authMiddleware, upload.single('photo'), uploadPhoto); 
router.delete('/me/photo', authMiddleware, deletePhoto); 

module.exports = router;