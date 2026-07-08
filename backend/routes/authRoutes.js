const express = require('express');
const { requestOtp, verifyOtp } = require('../controllers/authController');

const router = express.Router();

// Route: POST /api/v1/auth/request-otp
router.post('/request-otp', requestOtp);

// Route: POST /api/v1/auth/verify-otp
router.post('/verify-otp', verifyOtp);

module.exports = router;
