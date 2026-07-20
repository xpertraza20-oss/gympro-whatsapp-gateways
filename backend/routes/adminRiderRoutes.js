'use strict';
const express = require('express');
const { pool } = require('../config/db');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/v1/admin/riders/pending
router.get('/pending', adminAuth, async (req, res, next) => {
  try {
    const result = await pool.query(`
      SELECT r.*, u.name as rider_name, u.phone as rider_phone, u.email as rider_email
      FROM riders r
      JOIN users u ON r.user_id = u.id
      WHERE r.verification_status = 'pending'
      ORDER BY r.id DESC;
    `);
    return res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/admin/riders
router.get('/', adminAuth, async (req, res, next) => {
  try {
    const result = await pool.query(`
      SELECT r.*, u.name as rider_name, u.phone as rider_phone, u.email as rider_email
      FROM riders r
      JOIN users u ON r.user_id = u.id
      ORDER BY r.id DESC;
    `);
    return res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/admin/riders/:id
router.get('/:id', adminAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT r.*, u.name as rider_name, u.phone as rider_phone, u.email as rider_email
      FROM riders r
      JOIN users u ON r.user_id = u.id
      WHERE r.id = $1;
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Rider not found.' });
    }
    return res.status(200).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/admin/riders/:id/approve
router.patch('/:id/approve', adminAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      UPDATE riders
      SET verification_status = 'approved', is_approved = true, approved_by = 'admin', approved_at = NOW()
      WHERE id = $1
      RETURNING *;
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Rider not found.' });
    }
    return res.status(200).json({ success: true, message: 'Rider approved successfully.', data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/admin/riders/:id/reject
router.patch('/:id/reject', adminAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    if (!reason) {
      return res.status(400).json({ success: false, message: 'Rejection reason is required.' });
    }

    const result = await pool.query(`
      UPDATE riders
      SET verification_status = 'rejected', is_approved = false, rejection_reason = $1, approved_by = 'admin', approved_at = NOW()
      WHERE id = $2
      RETURNING *;
    `, [reason, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Rider not found.' });
    }
    return res.status(200).json({ success: true, message: 'Rider rejected successfully.', data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/admin/riders/:id/suspend
router.patch('/:id/suspend', adminAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    if (!reason) {
      return res.status(400).json({ success: false, message: 'Suspension reason is required.' });
    }

    const result = await pool.query(`
      UPDATE riders
      SET verification_status = 'suspended', is_approved = false, suspension_reason = $1, approved_by = 'admin', approved_at = NOW()
      WHERE id = $2
      RETURNING *;
    `, [reason, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Rider not found.' });
    }
    return res.status(200).json({ success: true, message: 'Rider suspended successfully.', data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
