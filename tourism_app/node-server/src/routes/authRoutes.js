const express = require('express');
const { registerUser, loginUser, verifyToken, updateProfile } = require('../controllers/authController');
const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/verify', verifyToken);
router.put('/profile', updateProfile);

module.exports = router;