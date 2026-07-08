const express = require('express');
const {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct
} = require('../controllers/productController');
const { generatePresignedUrl } = require('../controllers/uploadController');
const { adminAuth } = require('../middlewares/auth');

const publicRouter = express.Router();
const adminRouter = express.Router();

// Public Endpoints (Mounted on /api/v1/products)
publicRouter.get('/', getProducts);
publicRouter.get('/:id', getProductById);

// Admin Endpoints (Mounted on /api/v1/admin/products)
adminRouter.post('/', adminAuth, createProduct);
adminRouter.put('/:id', adminAuth, updateProduct);
adminRouter.delete('/:id', adminAuth, deleteProduct);
adminRouter.post('/presign', adminAuth, generatePresignedUrl); // Presigned upload endpoint

module.exports = {
  publicRouter,
  adminRouter
};
