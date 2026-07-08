const { pool } = require('../config/db');

/**
 * Places a new order
 * POST /api/v1/orders
 */
const placeOrder = async (req, res, next) => {
  const { items, delivery_address, total_amount, payment_method = 'COD' } = req.body;
  const userId = req.user.id;

  if (!items || !delivery_address || total_amount === undefined) {
    return res.status(400).json({
      success: false,
      message: 'Items, delivery address, and total amount are required.'
    });
  }

  try {
    const query = `
      INSERT INTO orders (user_id, delivery_address, total_amount, payment_method, items, status)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const values = [
      userId,
      delivery_address,
      total_amount,
      payment_method,
      JSON.stringify(items),
      'Pending'
    ];

    const result = await pool.query(query, values);
    
    return res.status(201).json({
      success: true,
      message: 'Order placed successfully.',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Error placing order:', err);
    next(err);
  }
};

/**
 * Retrieves the history of orders for the authenticated user
 * GET /api/v1/orders/history
 */
const getOrderHistory = async (req, res, next) => {
  const userId = req.user.id;

  try {
    const query = `
      SELECT * FROM orders
      WHERE user_id = $1
      ORDER BY created_at DESC;
    `;
    const result = await pool.query(query, [userId]);

    return res.status(200).json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error('Error fetching order history:', err);
    next(err);
  }
};

/**
 * Retrieves a single order by ID to track status
 * GET /api/v1/orders/:id
 */
const getOrderById = async (req, res, next) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    const query = `
      SELECT * FROM orders
      WHERE id = $1 AND user_id = $2;
    `;
    const result = await pool.query(query, [parseInt(id, 10), userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.'
      });
    }

    return res.status(200).json({
      success: true,
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Error fetching order by id:', err);
    next(err);
  }
};

module.exports = {
  placeOrder,
  getOrderHistory,
  getOrderById,
  
  // Admin endpoints
  adminGetAllOrders: async (req, res, next) => {
    try {
      const query = `
        SELECT 
          o.id,
          o.delivery_address,
          o.total_amount,
          o.payment_method,
          o.status,
          o.items,
          o.created_at,
          u.name AS customer_name,
          u.email AS customer_email
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        ORDER BY o.created_at DESC;
      `;
      const result = await pool.query(query);

      return res.status(200).json({
        success: true,
        data: result.rows.map(row => ({
          id: row.id,
          customerName: row.customer_name || 'Anonymous',
          email: row.customer_email || 'N/A',
          itemsCount: Array.isArray(row.items) ? row.items.length : 0,
          totalAmount: parseFloat(row.total_amount),
          status: row.status,
          date: new Date(row.created_at).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
          }),
          paymentMethod: row.payment_method
        }))
      });
    } catch (err) {
      console.error('Error in adminGetAllOrders:', err);
      next(err);
    }
  },

  adminUpdateOrderStatus: async (req, res, next) => {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is a required field.'
      });
    }

    try {
      const query = `
        UPDATE orders
        SET status = $1
        WHERE id = $2
        RETURNING *;
      `;
      const result = await pool.query(query, [status, parseInt(id, 10)]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Order not found.'
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Order status updated successfully.',
        data: result.rows[0]
      });
    } catch (err) {
      console.error('Error in adminUpdateOrderStatus:', err);
      next(err);
    }
  }
};
