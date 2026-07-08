const express = require('express');
const {
  createCategory,
  getCategories,
  updateCategory,
  deleteCategory
} = require('../controllers/categoryController');
const { adminAuth } = require('../middlewares/auth');

const publicRouter = express.Router();
const adminRouter = express.Router();

// Public Endpoints (Mounted on /api/v1/categories)
publicRouter.get('/', getCategories);

// Admin Endpoints (Mounted on /api/v1/admin/categories)
adminRouter.post('/', adminAuth, createCategory);
adminRouter.put('/:id', adminAuth, updateCategory);
adminRouter.delete('/:id', adminAuth, deleteCategory);

module.exports = {
  publicRouter,
  adminRouter
};
