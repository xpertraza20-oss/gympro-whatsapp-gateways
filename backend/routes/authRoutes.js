const express = require('express');
const {
  signup,
  login,
  verifyOtp,
  requestOtp,          // legacy phone OTP
} = require('../controllers/authController');

const router = express.Router();

// ─── Email OTP Routes ──────────────────────────────────────────────────────
// POST /api/v1/auth/signup       → name, email, phone → sends email OTP
router.post('/signup', signup);

// POST /api/v1/auth/login        → email → sends email OTP (login)
router.post('/login', login);

// POST /api/v1/auth/verify-otp   → email, otp → validates + returns JWT
router.post('/verify-otp', verifyOtp);

// ─── Legacy Phone OTP Route (kept for mobile client backward compatibility)
// POST /api/v1/auth/request-otp  → phoneNumber → sends console OTP
router.post('/request-otp', requestOtp);

module.exports = router;
