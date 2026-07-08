'use strict';
const { pool } = require('../config/db');

/**
 * GET /api/v1/admin/users
 * Returns all verified customers, paginated, newest first.
 */
exports.getAllUsers = async (req, res, next) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    // Count total verified users
    const countRes = await pool.query(
      `SELECT COUNT(*) FROM users WHERE is_verified = true`
    );
    const total = parseInt(countRes.rows[0].count, 10);

    // Fetch paginated results
    const usersRes = await pool.query(
      `SELECT
         id,
         name,
         email,
         COALESCE(phone, phone_number) AS phone,
         is_verified,
         created_at
       FROM users
       WHERE is_verified = true
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const totalPages = Math.ceil(total / limit);

    return res.status(200).json({
      success: true,
      data: {
        users: usersRes.rows.map(u => ({
          id:          u.id,
          name:        u.name  || 'N/A',
          email:       u.email || 'N/A',
          phone:       u.phone || 'N/A',
          joining_date: new Date(u.created_at).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
          }),
          is_verified: u.is_verified,
        })),
        pagination: {
          page,
          limit,
          total,
          total_pages: totalPages,
          has_next:    page < totalPages,
          has_prev:    page > 1,
        }
      }
    });
  } catch (err) {
    console.error('Error in getAllUsers:', err);
    next(err);
  }
};

/**
 * PUT /api/v1/admin/users/:id
 * Updates customer details (name, email, phone)
 */
exports.updateUser = async (req, res, next) => {
  const { id } = req.params;
  const { name, email, phone } = req.body;

  if (!name || !email) {
    return res.status(400).json({
      success: false,
      message: 'Name and email are required fields.'
    });
  }

  try {
    // Check if email conflict exists for another user
    const conflictRes = await pool.query(
      'SELECT id FROM users WHERE email = $1 AND id != $2',
      [email.toLowerCase().trim(), id]
    );

    if (conflictRes.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'This email is already in use by another customer.'
      });
    }

    const updateRes = await pool.query(
      `UPDATE users
       SET name = $1, email = $2, phone = $3, phone_number = $3
       WHERE id = $4
       RETURNING *`,
      [name.trim(), email.toLowerCase().trim(), phone ? phone.trim() : null, id]
    );

    if (updateRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found.'
      });
    }

    const updated = updateRes.rows[0];

    return res.status(200).json({
      success: true,
      message: 'Customer details updated successfully.',
      user: {
        id: updated.id,
        name: updated.name,
        email: updated.email,
        phone: updated.phone || updated.phone_number || 'N/A'
      }
    });
  } catch (err) {
    console.error('Error in updateUser:', err);
    next(err);
  }
};

/**
 * DELETE /api/v1/admin/users/:id
 * Deletes a customer account from database
 */
exports.deleteUser = async (req, res, next) => {
  const { id } = req.params;

  try {
    const deleteRes = await pool.query(
      'DELETE FROM users WHERE id = $1 RETURNING *',
      [id]
    );

    if (deleteRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found.'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Customer account successfully deleted.'
    });
  } catch (err) {
    console.error('Error in deleteUser:', err);
    next(err);
  }
};
