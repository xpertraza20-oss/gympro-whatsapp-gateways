const { pool } = require('../config/db');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'grocery-app-super-secret-jwt-key';

/**
 * Handles Request OTP endpoint
 * POST /api/v1/auth/request-otp
 */
exports.requestOtp = async (req, res, next) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Phone number is required'
    });
  }

  try {
    // Generate a 6-digit OTP (123456 for testing, or random code)
    // We will generate a random 6-digit number, but for simplicity of verification,
    // let's log it clearly to the console so the developer can see it.
    const otp = process.env.NODE_ENV === 'production' 
      ? String(Math.floor(100000 + Math.random() * 900000))
      : '123456'; // Default mock for development

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiration

    // Upsert into otps table
    const query = `
      INSERT INTO otps (phone_number, otp, expires_at)
      VALUES ($1, $2, $3)
      ON CONFLICT (phone_number)
      DO UPDATE SET otp = EXCLUDED.otp, expires_at = EXCLUDED.expires_at;
    `;
    await pool.query(query, [phoneNumber, otp, expiresAt]);

    console.log(`=========================================`);
    console.log(`📲 [SMS OTP Simulation]`);
    console.log(`To: ${phoneNumber}`);
    console.log(`Code: ${otp}`);
    console.log(`Expires: ${expiresAt.toISOString()}`);
    console.log(`=========================================`);

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      // Return OTP directly in response for development convenience
      ...(process.env.NODE_ENV !== 'production' && { debugOtp: otp })
    });
  } catch (err) {
    console.error('Error in requestOtp controller:', err);
    next(err);
  }
};

/**
 * Handles Verify OTP endpoint
 * POST /api/v1/auth/verify-otp
 */
exports.verifyOtp = async (req, res, next) => {
  const { phoneNumber, otp } = req.body;
  if (!phoneNumber || !otp) {
    return res.status(400).json({
      success: false,
      message: 'Phone number and OTP code are required'
    });
  }

  try {
    // 1. Fetch OTP record
    const otpRes = await pool.query('SELECT * FROM otps WHERE phone_number = $1', [phoneNumber]);
    if (otpRes.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP or phone number'
      });
    }

    const record = otpRes.rows[0];

    // 2. Validate OTP value
    if (record.otp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Incorrect OTP code'
      });
    }

    // 3. Validate expiration
    if (new Date(record.expires_at) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'OTP code has expired'
      });
    }

    // 4. Clean up verified OTP
    await pool.query('DELETE FROM otps WHERE phone_number = $1', [phoneNumber]);

    // 5. Get or Create User
    let userRes = await pool.query('SELECT * FROM users WHERE phone_number = $1', [phoneNumber]);
    let user;
    if (userRes.rows.length === 0) {
      const createUserRes = await pool.query(
        'INSERT INTO users (phone_number) VALUES ($1) RETURNING *',
        [phoneNumber]
      );
      user = createUserRes.rows[0];
      console.log(`👤 New user registered: ${phoneNumber} (ID: ${user.id})`);
    } else {
      user = userRes.rows[0];
    }

    // 6. Generate JWT Token
    const token = jwt.sign(
      { id: user.id, phoneNumber: user.phone_number },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return res.status(200).json({
      success: true,
      token,
      user: {
        id: user.id,
        phone_number: user.phone_number,
        name: user.name || '',
        email: user.email || ''
      }
    });
  } catch (err) {
    console.error('Error in verifyOtp controller:', err);
    next(err);
  }
};
