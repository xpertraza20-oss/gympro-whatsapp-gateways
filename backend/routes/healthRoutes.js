const express = require('express');
const { getHealth, getDbHealth } = require('../controllers/healthController');

const router = express.Router();

// Route: GET /api/health
router.get('/', getHealth);

// Route: GET /api/health/db
router.get('/db', getDbHealth);

module.exports = router;
