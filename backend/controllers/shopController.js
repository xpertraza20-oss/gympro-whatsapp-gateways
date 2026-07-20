'use strict';
const { pool } = require('../config/db');

exports.registerShop = async (req, res, next) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(401).json({ success: false, message: 'Unauthorized.' });
  }

  const {
    shop_name,
    shop_address,
    map_location,
    cnic,
    opening_time,
    closing_time,
    image_url
  } = req.body;

  if (!shop_name || !shop_address || !cnic) {
    return res.status(400).json({
      success: false,
      message: 'Shop name, address, and owner CNIC are required.'
    });
  }

  try {
    // Check if user already has a shop
    const existing = await pool.query('SELECT id FROM shops WHERE owner_id = $1 LIMIT 1;', [userId]);
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'A shop profile already exists for this account.'
      });
    }

    // Insert shop
    const result = await pool.query(
      `INSERT INTO shops (owner_id, shop_name, shop_address, map_location, cnic, status, opening_time, closing_time, image_url)
       VALUES ($1, $2, $3, $4, $5, 'pending', $6, $7, $8)
       RETURNING *;`,
      [userId, shop_name, shop_address, map_location || null, cnic, opening_time || null, closing_time || null, image_url || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Shop registered successfully and is pending admin approval.',
      shop: result.rows[0]
    });
  } catch (err) {
    console.error('Error registering shop:', err);
    next(err);
  }
};
