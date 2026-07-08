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
