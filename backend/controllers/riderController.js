'use strict';
const { pool } = require('../config/db');

exports.registerRider = async (req, res, next) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(401).json({ success: false, message: 'Unauthorized.' });
  }

  const {
    vehicle_type,
    vehicle_number,
    cnic,
    current_location
  } = req.body;

  if (!vehicle_type || !vehicle_number || !cnic) {
    return res.status(400).json({
      success: false,
      message: 'Vehicle type, vehicle number, and CNIC are required.'
    });
  }

  try {
    // Check if user already registered as rider
    const existing = await pool.query('SELECT id FROM riders WHERE user_id = $1 LIMIT 1;', [userId]);
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'A rider profile already exists for this account.'
      });
    }

    // Insert rider (is_approved defaults to false, status defaults to offline)
    const result = await pool.query(
      `INSERT INTO riders (user_id, vehicle_type, vehicle_number, cnic, status, is_approved, current_location)
       VALUES ($1, $2, $3, $4, 'offline', false, $5)
       RETURNING *;`,
      [userId, vehicle_type, vehicle_number, cnic, current_location || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Rider registered successfully and is pending admin approval.',
      rider: result.rows[0]
    });
  } catch (err) {
    console.error('Error registering rider:', err);
    next(err);
  }
};
