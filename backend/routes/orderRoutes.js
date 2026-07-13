const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authenticateUser } = require('../middlewares/auth');

router.post('/', authenticateUser, orderController.placeOrder);
router.get('/history', authenticateUser, orderController.getOrderHistory);
router.get('/:id', authenticateUser, orderController.getOrderById);
router.put('/:id/cancel', authenticateUser, orderController.cancelOrder);
router.delete('/:id', authenticateUser, orderController.deleteOrder);

module.exports = router;
