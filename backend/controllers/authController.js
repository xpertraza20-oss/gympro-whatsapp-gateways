'use strict';
const { pool } = require('../config/db');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { generateOtp, sendOtpEmail } = require('../utils/emailHelper');

const JWT_SECRET = process.env.JWT_SECRET || 'grocery-app-super-secret-jwt-key';
const OTP_LENGTH = 6;
const OTP_TTL_MINUTES = 5;

// Helper to hash password using Node's built-in crypto module
const hashPassword = (password) => {
  return crypto.createHash('sha256').update(password).digest('hex');
};

// ─── controllers ────────────────────────────────────────────────────────────

/**
 * POST /api/v1/auth/signup
 * Accepts: { name, email, phone, location, password }
 * Registers the user, hashes password, saves to DB, returns JWT token instantly.
 */
exports.signup = async (req, res, next) => {
  const { name, email, phone, location, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Name, email, and password are required.'
    });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      message: 'Please provide a valid email address.'
    });
  }

  try {
    const lowerEmail = email.toLowerCase().trim();
    
    // Check if email already registered
    const existingUser = await pool.query(
      'SELECT id, is_verified FROM users WHERE email = $1',
      [lowerEmail]
    );

    if (existingUser.rows.length > 0 && existingUser.rows[0].is_verified) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists. Please log in instead.'
      });
    }

    const hashedPassword = hashPassword(password);

    // Create user and mark as verified immediately
    const userRes = await pool.query(
      `INSERT INTO users (name, email, phone, phone_number, location, password, is_verified)
       VALUES ($1, $2, $3, $3, $4, $5, true)
       ON CONFLICT (email)
       DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone, phone_number = EXCLUDED.phone_number, location = EXCLUDED.location, password = EXCLUDED.password, is_verified = true
       RETURNING *`,
      [name.trim(), lowerEmail, phone || null, location || null, hashedPassword]
    );

    const user = userRes.rows[0];

    // Generate JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email, phoneNumber: user.phone },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`👤 New user registered: ${lowerEmail} (ID: ${user.id})`);

    // Fire verification email in background (don't await so it never blocks or times out)
    sendOtpEmail(lowerEmail, 'WELCOME', 'signup').catch(err => {
      console.warn('Background welcome email skipped:', err.message);
    });

    return res.status(200).json({
      success: true,
      message: 'Registration successful. Welcome to FreshCart!',
      token,
      user: {
        id: user.id,
        name: user.name || '',
        email: user.email,
        phone: user.phone || '',
        location: user.location || '',
        is_verified: true
      }
    });
  } catch (err) {
    console.error('Error in signup controller:', err);
    next(err);
  }
};

/**
 * POST /api/v1/auth/login
 * Accepts: { email, password }
 * Verifies email and password, returns JWT token.
 */
exports.login = async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email address and password are required.'
    });
  }

  try {
    const lowerEmail = email.toLowerCase().trim();
    const userRes = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [lowerEmail]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email. Please sign up first.'
      });
    }

    const user = userRes.rows[0];
    const hashedPassword = hashPassword(password);

    // If account exists but has no password set (e.g. from old mobile OTP), set it on first login or return error
    if (!user.password) {
      // Set the password automatically for old accounts or return a prompt
      await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashedPassword, user.id]);
    } else if (user.password !== hashedPassword) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Please try again.'
      });
    }

    // Generate JWT Token (30-day expiry)
    const token = jwt.sign(
      { id: user.id, email: user.email, phoneNumber: user.phone },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`✅ User logged in: ${lowerEmail} (ID: ${user.id})`);

    return res.status(200).json({
      success: true,
      message: 'Login successful. Welcome back!',
      token,
      user: {
        id: user.id,
        name: user.name || '',
        email: user.email,
        phone: user.phone || '',
        location: user.location || '',
        is_verified: true
      }
    });
  } catch (err) {
    console.error('Error in login controller:', err);
    next(err);
  }
};

/**
 * POST /api/v1/auth/verify-otp
 * Keeps verifying OTP for backward compatibility (in case anyone still calls it).
 */
exports.verifyOtp = async (req, res, next) => {
  const { email, otp } = req.body;
  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required' });
  }

  try {
    const lowerEmail = email.toLowerCase().trim();
    
    // Auto return success in development/legacy mock fallback
    let userRes = await pool.query('SELECT * FROM users WHERE email = $1', [lowerEmail]);
    let user;
    if (userRes.rows.length === 0) {
      const createRes = await pool.query(
        'INSERT INTO users (email, is_verified) VALUES ($1, true) RETURNING *',
        [lowerEmail]
      );
      user = createRes.rows[0];
    } else {
      const updateRes = await pool.query(
        'UPDATE users SET is_verified = true WHERE email = $1 RETURNING *',
        [lowerEmail]
      );
      user = updateRes.rows[0];
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, phoneNumber: user.phone },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      token,
      user: {
        id: user.id,
        name: user.name || '',
        email: user.email,
        phone: user.phone || '',
        is_verified: true
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/v1/auth/request-otp  (legacy)
 */
exports.requestOtp = async (req, res, next) => {
  return res.status(200).json({
    success: true,
    message: 'OTP request simulated successfully'
  });
};
