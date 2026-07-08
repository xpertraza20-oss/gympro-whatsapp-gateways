'use strict';
const { pool } = require('../config/db');
const jwt = require('jsonwebtoken');
const { generateOtp, sendOtpEmail } = require('../utils/emailHelper');

const JWT_SECRET = process.env.JWT_SECRET || 'grocery-app-super-secret-jwt-key';
const OTP_LENGTH = 6;
const OTP_TTL_MINUTES = 5;

// ─── helpers ────────────────────────────────────────────────────────────────

/**
 * Deletes all existing OTPs for the given email and inserts a fresh one.
 * Returns the generated OTP string.
 */
const upsertEmailOtp = async (email, otp) => {
  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

  // Remove stale OTPs for this email first
  await pool.query('DELETE FROM otps WHERE email = $1', [email]);

  // Insert fresh OTP record
  await pool.query(
    'INSERT INTO otps (email, otp, expires_at) VALUES ($1, $2, $3)',
    [email, otp, expiresAt]
  );

  return { otp, expiresAt };
};

/**
 * Validates an OTP for the given email. Returns the OTP row if valid.
 * Throws a structured error object otherwise.
 */
const validateEmailOtp = async (email, otp) => {
  const result = await pool.query(
    'SELECT * FROM otps WHERE email = $1 ORDER BY created_at DESC LIMIT 1',
    [email]
  );

  if (result.rows.length === 0) {
    throw { statusCode: 400, message: 'No pending OTP found for this email. Please request a new code.' };
  }

  const record = result.rows[0];

  if (record.otp !== otp) {
    throw { statusCode: 400, message: 'Incorrect OTP code. Please check your email and try again.' };
  }

  if (new Date(record.expires_at) < new Date()) {
    await pool.query('DELETE FROM otps WHERE email = $1', [email]);
    throw { statusCode: 400, message: 'OTP code has expired. Please request a new one.' };
  }

  // Cleanup after successful validation
  await pool.query('DELETE FROM otps WHERE email = $1', [email]);

  return record;
};

// ─── controllers ────────────────────────────────────────────────────────────

/**
 * POST /api/v1/auth/signup
 * Accepts: { name, email, phone }
 * Validates fields, creates a pending user if first-time, sends Email OTP.
 */
exports.signup = async (req, res, next) => {
  const { name, email, phone } = req.body;

  if (!name || !email) {
    return res.status(400).json({
      success: false,
      message: 'Name and email are required.'
    });
  }

  // Simple email format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      message: 'Please provide a valid email address.'
    });
  }

  try {
    // Check if email is already registered and verified
    const existingUser = await pool.query(
      'SELECT id, is_verified FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (existingUser.rows.length > 0 && existingUser.rows[0].is_verified) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists. Please log in instead.'
      });
    }

    // Upsert user record (pending verification)
    await pool.query(
      `INSERT INTO users (name, email, phone, is_verified)
       VALUES ($1, $2, $3, false)
       ON CONFLICT (email)
       DO UPDATE SET name = EXCLUDED.name, phone = EXCLUDED.phone`,
      [name.trim(), email.toLowerCase(), phone || null]
    );

    // Generate and send OTP
    const otp = process.env.NODE_ENV === 'production'
      ? generateOtp(OTP_LENGTH)
      : '123456'; // Fixed OTP for development/testing

    const { expiresAt } = await upsertEmailOtp(email.toLowerCase(), otp);

    let previewUrl = null;
    try {
      previewUrl = await sendOtpEmail(email.toLowerCase(), otp, 'signup');
    } catch (emailErr) {
      console.error('⚠️ Email sending failed (non-fatal):', emailErr.message);
    }

    return res.status(200).json({
      success: true,
      message: `Verification code sent to ${email}. Check your inbox.`,
      expiresAt: expiresAt.toISOString(),
      // Development helpers
      ...(process.env.NODE_ENV !== 'production' && {
        debugOtp: otp,
        ...(previewUrl && { emailPreviewUrl: previewUrl })
      })
    });
  } catch (err) {
    console.error('Error in signup controller:', err);
    next(err);
  }
};

/**
 * POST /api/v1/auth/login
 * Accepts: { email }
 * Checks if user exists and is verified. Sends Email OTP for login.
 */
exports.login = async (req, res, next) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      message: 'Email address is required.'
    });
  }

  try {
    const userRes = await pool.query(
      'SELECT id, name, email, is_verified FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email. Please sign up first.'
      });
    }

    const user = userRes.rows[0];

    // Generate and send OTP
    const otp = process.env.NODE_ENV === 'production'
      ? generateOtp(OTP_LENGTH)
      : '123456';

    const { expiresAt } = await upsertEmailOtp(email.toLowerCase(), otp);

    let previewUrl = null;
    try {
      previewUrl = await sendOtpEmail(email.toLowerCase(), otp, 'login');
    } catch (emailErr) {
      console.error('⚠️ Email sending failed (non-fatal):', emailErr.message);
    }

    return res.status(200).json({
      success: true,
      message: `Login code sent to ${email}. Check your inbox.`,
      expiresAt: expiresAt.toISOString(),
      // Development helpers
      ...(process.env.NODE_ENV !== 'production' && {
        debugOtp: otp,
        ...(previewUrl && { emailPreviewUrl: previewUrl })
      })
    });
  } catch (err) {
    console.error('Error in login controller:', err);
    next(err);
  }
};

/**
 * POST /api/v1/auth/verify-otp
 * Accepts: { email, otp }
 * Validates OTP, marks user as verified, returns JWT + user profile.
 */
exports.verifyOtp = async (req, res, next) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Email and OTP code are required.'
    });
  }

  try {
    // Validate the OTP
    await validateEmailOtp(email.toLowerCase(), String(otp).trim());

    // Fetch or create the user and mark as verified
    let userRes = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    let user;
    if (userRes.rows.length === 0) {
      // Auto-create user if they skipped signup (e.g. direct OTP link)
      const createRes = await pool.query(
        'INSERT INTO users (email, is_verified) VALUES ($1, true) RETURNING *',
        [email.toLowerCase()]
      );
      user = createRes.rows[0];
      console.log(`👤 Auto-created and verified user: ${email} (ID: ${user.id})`);
    } else {
      // Mark user as verified
      const updateRes = await pool.query(
        'UPDATE users SET is_verified = true WHERE email = $1 RETURNING *',
        [email.toLowerCase()]
      );
      user = updateRes.rows[0];
    }

    // Generate a JWT token (30-day expiry)
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        phoneNumber: user.phone || user.phone_number
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`✅ User authenticated: ${email} (ID: ${user.id})`);

    return res.status(200).json({
      success: true,
      message: 'Email verified successfully. Welcome to FreshCart!',
      token,
      user: {
        id: user.id,
        name: user.name || '',
        email: user.email,
        phone: user.phone || user.phone_number || '',
        is_verified: true
      }
    });
  } catch (err) {
    // Structured error from validateEmailOtp helper
    if (err.statusCode) {
      return res.status(err.statusCode).json({
        success: false,
        message: err.message
      });
    }
    console.error('Error in verifyOtp controller:', err);
    next(err);
  }
};

// ─── Legacy phone-based endpoint (kept for backward compatibility) ───────────

/**
 * POST /api/v1/auth/request-otp  (legacy phone OTP — kept for Flutter mobile client)
 */
exports.requestOtp = async (req, res, next) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ success: false, message: 'Phone number is required' });
  }

  try {
    const otp = process.env.NODE_ENV === 'production'
      ? generateOtp(6)
      : '123456';

    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    // Use phone_number column for legacy records
    await pool.query('DELETE FROM otps WHERE phone_number = $1', [phoneNumber]);
    await pool.query(
      'INSERT INTO otps (phone_number, otp, expires_at) VALUES ($1, $2, $3)',
      [phoneNumber, otp, expiresAt]
    );

    console.log(`📲 [SMS OTP Simulation] To: ${phoneNumber}  Code: ${otp}`);

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      ...(process.env.NODE_ENV !== 'production' && { debugOtp: otp })
    });
  } catch (err) {
    next(err);
  }
};
