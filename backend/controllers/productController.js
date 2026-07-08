const { pool } = require('../config/db');

/**
 * Creates a new product. (Admin only)
 * Saves product details and the final Cloudflare R2 download URL.
 */
const createProduct = async (req, res, next) => {
  try {
    const {
      category_id,
      title,
      description,
      price,
      sale_price,
      unit,
      stock_quantity,
      is_available,
      image_url
    } = req.body;

    // Validation
    if (!title || price === undefined) {
      const error = new Error('Product title and price are required');
      error.statusCode = 400;
      return next(error);
    }

    const queryText = `
      INSERT INTO products (
        category_id, title, description, price, sale_price, 
        unit, stock_quantity, is_available, image_url
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *;
    `;

    const values = [
      category_id || null,
      title,
      description || null,
      price,
      sale_price !== undefined ? sale_price : null,
      unit || null,
      stock_quantity !== undefined ? stock_quantity : 0,
      is_available !== undefined ? is_available : true,
      image_url || null
    ];

    const result = await pool.query(queryText, values);

    res.status(201).json({
      success: true,
      message: 'Product created successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Public endpoint to fetch products.
 * Supports strict pagination (?page=1&limit=20),
 * category filtering (?category_id=X), and full-text keyword search (?search=apple).
 */
const getProducts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, category_id, search } = req.query;

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;
    const offset = (pageNum - 1) * limitNum;

    // Construct dynamic WHERE conditions
    const conditions = [];
    const queryParams = [];

    if (category_id) {
      queryParams.push(parseInt(category_id, 10));
      conditions.push(`p.category_id = $${queryParams.length}`);
    }

    if (search && search.trim() !== '') {
      queryParams.push(search.trim());
      // Utilize the full-text GIN index on title using plainto_tsquery
      conditions.push(`to_tsvector('english', p.title) @@ plainto_tsquery('english', $${queryParams.length})`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // 1. Get total count of matching products
    const countQuery = `
      SELECT COUNT(*) 
      FROM products p
      ${whereClause};
    `;
    const countResult = await pool.query(countQuery, queryParams);
    const totalItems = parseInt(countResult.rows[0].count, 10);

    // 2. Fetch paginated products joined with category names
    const itemsParams = [...queryParams];
    
    itemsParams.push(limitNum);
    const limitPlaceholder = `$${itemsParams.length}`;

    itemsParams.push(offset);
    const offsetPlaceholder = `$${itemsParams.length}`;

    const itemsQuery = `
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ${whereClause}
      ORDER BY p.created_at DESC
      LIMIT ${limitPlaceholder} OFFSET ${offsetPlaceholder};
    `;

    const itemsResult = await pool.query(itemsQuery, itemsParams);
    const totalPages = Math.ceil(totalItems / limitNum);

    res.status(200).json({
      success: true,
      pagination: {
        totalItems,
        totalPages,
        page: pageNum,
        limit: limitNum
      },
      data: itemsResult.rows
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Returns a single product by ID. (Public)
 */
const getProductById = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const queryText = `
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = $1;
    `;
    const result = await pool.query(queryText, [id]);

    if (result.rowCount === 0) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      return next(error);
    }

    res.status(200).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Updates an existing product. (Admin only)
 */
const updateProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      category_id,
      title,
      description,
      price,
      sale_price,
      unit,
      stock_quantity,
      is_available,
      image_url
    } = req.body;

    if (!title || price === undefined) {
      const error = new Error('Product title and price are required');
      error.statusCode = 400;
      return next(error);
    }

    const queryText = `
      UPDATE products
      SET 
        category_id = $1,
        title = $2,
        description = $3,
        price = $4,
        sale_price = $5,
        unit = $6,
        stock_quantity = $7,
        is_available = $8,
        image_url = $9
      WHERE id = $10
      RETURNING *;
    `;

    const values = [
      category_id || null,
      title,
      description || null,
      price,
      sale_price !== undefined ? sale_price : null,
      unit || null,
      stock_quantity !== undefined ? stock_quantity : 0,
      is_available !== undefined ? is_available : true,
      image_url || null,
      id
    ];

    const result = await pool.query(queryText, values);

    if (result.rowCount === 0) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      return next(error);
    }

    res.status(200).json({
      success: true,
      message: 'Product updated successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Deletes a product. (Admin only)
 */
const deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM products WHERE id = $1 RETURNING *;', [id]);

    if (result.rowCount === 0) {
      const error = new Error('Product not found');
      error.statusCode = 404;
      return next(error);
    }

    res.status(200).json({
      success: true,
      message: 'Product deleted successfully.',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct
};
