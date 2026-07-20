const express = require('express');
const { registerRider } = require('../controllers/riderController');
const { authenticateUser } = require('../middlewares/auth');

const router = express.Router();

// POST /api/v1/riders  → registers rider profile for rider
router.post('/', authenticateUser, registerRider);

module.exports = router;
