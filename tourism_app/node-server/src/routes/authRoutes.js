const express = require('express');
const { registerUser, loginUser, verifyToken, refreshToken, updateProfile } = require('../controllers/authController');
const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/verify', verifyToken);
router.post('/refresh', refreshToken);
router.put('/profile', updateProfile);

module.exports = router;