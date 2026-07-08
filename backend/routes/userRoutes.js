const express = require('express');
const { getAllUsers, updateUser, deleteUser } = require('../controllers/userController');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// GET /api/v1/admin/users?page=1&limit=20
router.get('/', adminAuth, getAllUsers);

// PUT /api/v1/admin/users/:id
router.put('/:id', adminAuth, updateUser);

// DELETE /api/v1/admin/users/:id
router.delete('/:id', adminAuth, deleteUser);

module.exports = router;
