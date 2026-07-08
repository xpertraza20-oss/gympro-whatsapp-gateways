const express = require('express');
const { adminGetAllOrders, adminUpdateOrderStatus } = require('../controllers/orderController');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/v1/admin/orders
router.get('/', adminAuth, adminGetAllOrders);

// PUT /api/v1/admin/orders/:id
router.put('/:id', adminAuth, adminUpdateOrderStatus);

module.exports = router;
