const express = require('express');
const { registerShop } = require('../controllers/shopController');
const { authenticateUser } = require('../middlewares/auth');

const router = express.Router();

// POST /api/v1/shops  → registers shop profile for shopkeeper
router.post('/', authenticateUser, registerShop);

module.exports = router;
