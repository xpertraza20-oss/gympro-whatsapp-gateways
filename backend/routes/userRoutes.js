const express = require('express');
const { getAllUsers } = require('../controllers/userController');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/v1/admin/users?page=1&limit=20
// Protected by adminAuth (requires X-Admin-Token or Authorization: Bearer <ADMIN_API_KEY>)
router.get('/', adminAuth, getAllUsers);

module.exports = router;
