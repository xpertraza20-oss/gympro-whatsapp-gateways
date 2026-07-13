'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { generateOtp, sendOtpEmail } = require('../utils/emailHelper');

const OTP_TTL_MINUTES = 5;
const PASSWORD_ITERATIONS = 120000;
const JWT_EXPIRES_IN = '30d';

const getJwtSecret = () => {
  if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
  if (process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET is required in production.');
  }
  return 'dev-only-grocery-jwt-secret';
};

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const sha256Hex = (value) => crypto.createHash('sha256').update(String(value)).digest('hex');

const hashPassword = (password) => {
  const salt = crypto.randomBytes(16);
  const hash = crypto.pbkdf2Sync(password, salt, PASSWORD_ITERATIONS, 32, 'sha256');
  return `pbkdf2$${PASSWORD_ITERATIONS}$${salt.toString('base64url')}$${hash.toString('base64url')}`;
};

const verifyPassword = (password, stored) => {
  if (!stored) return false;
  if (!stored.startsWith('pbkdf2$')) {
    return sha256Hex(password) === stored;
  }

  const [, iterationText, saltText, hashText] = stored.split('$');
  const iterations = Number(iterationText);
  const salt = Buffer.from(saltText, 'base64url');
  const expected = Buffer.from(hashText, 'base64url');
  const actual = crypto.pbkdf2Sync(password, salt, iterations, expected.length, 'sha256');
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
};

const issueToken = (user) => jwt.sign(
  { id: user.id, email: user.email, phoneNumber: user.phone || user.phone_number || '' },
  getJwtSecret(),
  { expiresIn: JWT_EXPIRES_IN }
);

const publicUser = (user) => ({
  id: user.id,
  name: user.name || '',
  email: user.email || '',
  phone: user.phone || user.phone_number || '',
  location: user.location || '',
  is_verified: Boolean(user.is_verified),
});

const storeOtp = async (email, otp) => {
  await pool.query('DELETE FROM otps WHERE email = $1;', [email]);
  await pool.query(
    `INSERT INTO otps (email, otp, expires_at)
     VALUES ($1, $2, NOW() + ($3 || ' minutes')::interval);`,
    [email, sha256Hex(otp), OTP_TTL_MINUTES]
  );
};

const sendAndStoreOtp = async (email, purpose) => {
  const otp = generateOtp(6);
  await storeOtp(email, otp);
  await sendOtpEmail(email, otp, purpose);
  return otp;
};

exports.signup = async (req, res, next) => {
  const { name, email, phone, location, password } = req.body;
  const lowerEmail = normalizeEmail(email);

  if (!name || !lowerEmail || !password) {
    return res.status(400).json({
      success: false,
      message: 'Name, email, and password are required.'
    });
  }

  if (!isValidEmail(lowerEmail)) {
    return res.status(400).json({
      success: false,
      message: 'Please provide a valid email address.'
    });
  }

  try {
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
    await pool.query(
      `INSERT INTO users (name, email, phone, phone_number, location, password, is_verified)
       VALUES ($1, $2, $3, $3, $4, $5, false)
       ON CONFLICT (email)
       DO UPDATE SET name = EXCLUDED.name,
         phone = EXCLUDED.phone,
         phone_number = EXCLUDED.phone_number,
         location = EXCLUDED.location,
         password = EXCLUDED.password,
         is_verified = false
       RETURNING *`,
      [name.trim(), lowerEmail, phone || null, location || null, hashedPassword]
    );

    const otp = await sendAndStoreOtp(lowerEmail, 'signup');
    return res.status(200).json({
      success: true,
      requiresOtp: true,
      email: lowerEmail,
      message: 'Verification code sent to your email.',
      ...(process.env.OTP_DELIVERY_MODE === 'debug' && { debugOtp: otp })
    });
  } catch (err) {
    console.error('Error in signup controller:', err);
    next(err);
  }
};

exports.login = async (req, res, next) => {
  const { email, password } = req.body;
  const lowerEmail = normalizeEmail(email);

  if (!lowerEmail || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email address and password are required.'
    });
  }

  try {
    const userRes = await pool.query('SELECT * FROM users WHERE email = $1', [lowerEmail]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email. Please sign up first.'
      });
    }

    const user = userRes.rows[0];
    if (!verifyPassword(password, user.password)) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password. Please try again.'
      });
    }

    if (user.password && !user.password.startsWith('pbkdf2$')) {
      await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashPassword(password), user.id]);
    }

    const otp = await sendAndStoreOtp(lowerEmail, 'login');
    return res.status(200).json({
      success: true,
      requiresOtp: true,
      email: lowerEmail,
      message: 'Login code sent to your email.',
      ...(process.env.OTP_DELIVERY_MODE === 'debug' && { debugOtp: otp })
    });
  } catch (err) {
    console.error('Error in login controller:', err);
    next(err);
  }
};

exports.verifyOtp = async (req, res, next) => {
  const email = normalizeEmail(req.body.email);
  const otp = String(req.body.otp || '').trim();

  if (!email || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Email and OTP are required.'
    });
  }

  try {
    const otpHash = sha256Hex(otp);
    const otpRes = await pool.query(
      `SELECT id FROM otps
       WHERE email = $1 AND (otp = $2 OR otp = $3) AND expires_at > NOW()
       ORDER BY created_at DESC
       LIMIT 1`,
      [email, otpHash, otp]
    );

    if (otpRes.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired OTP code.'
      });
    }

    await pool.query('DELETE FROM otps WHERE email = $1;', [email]);
    const userRes = await pool.query(
      'UPDATE users SET is_verified = true WHERE email = $1 RETURNING *',
      [email]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.'
      });
    }

    const user = userRes.rows[0];
    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      token: issueToken(user),
      user: publicUser(user)
    });
  } catch (err) {
    next(err);
  }
};

exports.requestOtp = async (req, res, next) => {
  const email = normalizeEmail(req.body.email || req.body.phoneNumber);
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({
      success: false,
      message: 'A valid email is required.'
    });
  }

  try {
    const userRes = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email.'
      });
    }

    const otp = await sendAndStoreOtp(email, req.body.purpose || 'login');
    return res.status(200).json({
      success: true,
      email,
      message: 'A fresh verification code has been sent.',
      ...(process.env.OTP_DELIVERY_MODE === 'debug' && { debugOtp: otp })
    });
  } catch (err) {
    next(err);
  }
};

exports.updateProfile = async (req, res, next) => {
  const { name, phone, location } = req.body;
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized. User session expired.'
    });
  }

  try {
    const updateRes = await pool.query(
      `UPDATE users
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           phone_number = COALESCE($2, phone_number),
           location = COALESCE($3, location)
       WHERE id = $4
       RETURNING *`,
      [name ? name.trim() : null, phone ? phone.trim() : null, location ? location.trim() : null, userId]
    );

    if (updateRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      user: publicUser(updateRes.rows[0])
    });
  } catch (err) {
    console.error('Error in updateProfile controller:', err);
    next(err);
  }
};
