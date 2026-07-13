const { pool } = require('../config/db');

const VALID_ORDER_STATUSES = ['Pending', 'Confirmed', 'Dispatched', 'Delivered', 'Cancelled'];

const normalizeOrderStatus = (status) => {
  const legacyMap = {
    Shipped: 'Dispatched',
    Completed: 'Delivered'
  };
  return legacyMap[status] || status;
};

const parseOrderItems = (items) => {
  if (Array.isArray(items)) return items;
  if (typeof items === 'string') {
    try {
      const parsed = JSON.parse(items);
      return Array.isArray(parsed) ? parsed : [];
    } catch (err) {
      return [];
    }
  }
  return [];
};

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

/**
 * Cancels an order with a reason
 * PUT /api/v1/orders/:id/cancel
 */
const cancelOrder = async (req, res, next) => {
  const { id } = req.params;
  const { reason } = req.body;
  const userId = req.user.id;

  if (!reason) {
    return res.status(400).json({
      success: false,
      message: 'Cancellation reason is required.'
    });
  }

  try {
    const findQuery = 'SELECT * FROM orders WHERE id = $1 AND user_id = $2;';
    const findResult = await pool.query(findQuery, [parseInt(id, 10), userId]);

    if (findResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.'
      });
    }

    const order = findResult.rows[0];
    if (order.status.toLowerCase() === 'delivered' || order.status.toLowerCase() === 'dispatched') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel an order that is already dispatched or delivered.'
      });
    }

    const updateQuery = `
      UPDATE orders
      SET status = 'Cancelled', cancel_reason = $1
      WHERE id = $2
      RETURNING *;
    `;
    const updateResult = await pool.query(updateQuery, [reason, parseInt(id, 10)]);

    return res.status(200).json({
      success: true,
      message: 'Order cancelled successfully.',
      data: updateResult.rows[0]
    });
  } catch (err) {
    console.error('Error in cancelOrder:', err);
    next(err);
  }
};

module.exports = {
  placeOrder,
  getOrderHistory,
  getOrderById,
  cancelOrder,
  
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
          o.cancel_reason,
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
          itemsCount: parseOrderItems(row.items).length,
          totalAmount: parseFloat(row.total_amount),
          status: normalizeOrderStatus(row.status),
          date: new Date(row.created_at).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
          }),
          paymentMethod: row.payment_method,
          deliveryAddress: row.delivery_address,
          delivery_address: row.delivery_address,
          cancelReason: row.cancel_reason || '',
          items: parseOrderItems(row.items),
          created_at: row.created_at
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

    const normalizedStatus = normalizeOrderStatus(status);

    if (!normalizedStatus || !VALID_ORDER_STATUSES.includes(normalizedStatus)) {
      return res.status(400).json({
        success: false,
        message: 'A valid status is required.'
      });
    }

    try {
      let query;
      let values;

      if (normalizedStatus === 'Cancelled') {
        const cancelReason = req.body.cancel_reason || 'Cancelled by administrator';
        query = `
          UPDATE orders
          SET status = $1, cancel_reason = $2
          WHERE id = $3
          RETURNING *;
        `;
        values = [normalizedStatus, cancelReason, parseInt(id, 10)];
      } else {
        query = `
          UPDATE orders
          SET status = $1, cancel_reason = NULL
          WHERE id = $2
          RETURNING *;
        `;
        values = [normalizedStatus, parseInt(id, 10)];
      }

      const result = await pool.query(query, values);

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
  },

  cancelOrder: async (req, res, next) => {
    const { id } = req.params;
    const { reason } = req.body;
    const userId = req.user.id;

    try {
      const checkRes = await pool.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2;',
        [parseInt(id, 10), userId]
      );

      if (checkRes.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Order not found.'
        });
      }

      const order = checkRes.rows[0];
      const normalizedStatus = order.status ? order.status.toLowerCase() : '';
      if (normalizedStatus !== 'pending' && normalizedStatus !== 'confirmed') {
        return res.status(400).json({
          success: false,
          message: 'Only pending or confirmed orders can be cancelled.'
        });
      }

      const updateQuery = `
        UPDATE orders
        SET status = 'Cancelled', cancel_reason = $1
        WHERE id = $2 AND user_id = $3
        RETURNING *;
      `;
      const result = await pool.query(updateQuery, [
        reason || 'User requested cancellation',
        parseInt(id, 10),
        userId
      ]);

      return res.status(200).json({
        success: true,
        message: 'Order cancelled successfully.',
        data: result.rows[0]
      });
    } catch (err) {
      console.error('Error in cancelOrder:', err);
      next(err);
    }
  },

  deleteOrder: async (req, res, next) => {
    const { id } = req.params;
    const userId = req.user.id;

    try {
      const checkRes = await pool.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2;',
        [parseInt(id, 10), userId]
      );

      if (checkRes.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Order not found.'
        });
      }

      await pool.query(
        'DELETE FROM orders WHERE id = $1 AND user_id = $2;',
        [parseInt(id, 10), userId]
      );

      return res.status(200).json({
        success: true,
        message: 'Order deleted successfully from history.'
      });
    } catch (err) {
      console.error('Error in deleteOrder:', err);
      next(err);
    }
  }
};
