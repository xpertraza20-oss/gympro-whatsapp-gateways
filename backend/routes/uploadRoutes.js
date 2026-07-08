const express = require('express');
const { generatePresignedUrl } = require('../controllers/uploadController');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// Endpoint: POST /api/v1/admin/products/presign
// Protected by adminAuth middleware
router.post('/presign', adminAuth, generatePresignedUrl);

module.exports = router;
