const { pool } = require('../config/db');

/**
 * Creates a new category. (Admin only)
 */
const createCategory = async (req, res, next) => {
  try {
    const { name, slug, image_url } = req.body;
    if (!name || !slug) {
      const error = new Error('Category name and slug are required');
      error.statusCode = 400;
      return next(error);
    }

    const queryText = `
      INSERT INTO categories (name, slug, image_url)
      VALUES ($1, $2, $3)
      RETURNING *;
    `;
    const result = await pool.query(queryText, [name, slug, image_url || null]);

    res.status(201).json({
      success: true,
      message: 'Category created successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') { // Postgres Unique Violation
      error.message = 'Category name or slug already exists';
      error.statusCode = 409; // Conflict
    }
    next(error);
  }
};

/**
 * Returns a list of all categories. (Public)
 */
const getCategories = async (req, res, next) => {
  try {
    const result = await pool.query('SELECT * FROM categories ORDER BY name ASC;');
    res.status(200).json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Updates an existing category. (Admin only)
 */
const updateCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, slug, image_url } = req.body;

    if (!name || !slug) {
      const error = new Error('Category name and slug are required');
      error.statusCode = 400;
      return next(error);
    }

    const queryText = `
      UPDATE categories
      SET name = $1, slug = $2, image_url = $3
      WHERE id = $4
      RETURNING *;
    `;
    const result = await pool.query(queryText, [name, slug, image_url || null, id]);

    if (result.rowCount === 0) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      return next(error);
    }

    res.status(200).json({
      success: true,
      message: 'Category updated successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') {
      error.message = 'Category name or slug already exists';
      error.statusCode = 409;
    }
    next(error);
  }
};

/**
 * Deletes an existing category. (Admin only)
 */
const deleteCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM categories WHERE id = $1 RETURNING *;', [id]);

    if (result.rowCount === 0) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      return next(error);
    }

    res.status(200).json({
      success: true,
      message: 'Category deleted successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createCategory,
  getCategories,
  updateCategory,
  deleteCategory
};
