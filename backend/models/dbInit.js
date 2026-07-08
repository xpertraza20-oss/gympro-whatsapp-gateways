const { pool } = require('../config/db');

/**
 * Initializes the database schemas by creating tables and optimization indexes
 * if they do not already exist.
 */
const initializeDatabase = async () => {
  const client = await pool.connect();
  try {
    console.log('Starting database initialization/migrations...');
    await client.query('BEGIN');

    // 1. Create categories table
    const createCategoriesTable = `
      CREATE TABLE IF NOT EXISTS categories (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        slug VARCHAR(255) NOT NULL UNIQUE,
        image_url TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await client.query(createCategoriesTable);
    console.log('Categories table checked/created.');

    // 2. Create products table
    const createProductsTable = `
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
        sale_price DECIMAL(10, 2) CHECK (sale_price IS NULL OR sale_price >= 0),
        unit VARCHAR(50),
        stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
        is_available BOOLEAN DEFAULT TRUE,
        image_url TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await client.query(createProductsTable);
    console.log('Products table checked/created.');

    // 2.1. Create users table
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        phone_number VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(255),
        email VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await client.query(createUsersTable);
    console.log('Users table checked/created.');

    // 2.2. Create otps table
    const createOtpsTable = `
      CREATE TABLE IF NOT EXISTS otps (
        phone_number VARCHAR(50) PRIMARY KEY,
        otp VARCHAR(6) NOT NULL,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL
      );
    `;
    await client.query(createOtpsTable);
    console.log('OTPs table checked/created.');

    // 3. Create B-Tree index on products(category_id)
    const createCategoryIdx = `
      CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
    `;
    await client.query(createCategoryIdx);
    console.log('B-Tree index on products(category_id) checked/created.');

    // 4. Create GIN index on to_tsvector('english', title) for fast full-text searching
    const createTitleGinIdx = `
      CREATE INDEX IF NOT EXISTS idx_products_title_gin ON products USING gin (to_tsvector('english', title));
    `;
    await client.query(createTitleGinIdx);
    console.log('GIN index on products(title) checked/created.');

    // 5. Seed default categories if empty, or patch image_urls if null
    const checkCategories = await client.query('SELECT COUNT(*) FROM categories;');
    if (parseInt(checkCategories.rows[0].count, 10) === 0) {
      console.log('Seeding default categories...');
      const seedQuery = `
        INSERT INTO categories (name, slug, image_url) VALUES
        ('Fruits', 'fruits', 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=200'),
        ('Vegetables', 'vegetables', 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?auto=format&fit=crop&q=80&w=200'),
        ('Dairy & Eggs', 'dairy-eggs', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=200'),
        ('Bakery', 'bakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200'),
        ('Meat & Seafood', 'meat-seafood', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&q=80&w=200'),
        ('Pantry Staples', 'pantry-staples', 'https://images.unsplash.com/photo-1549203396-abae8a36a77b?auto=format&fit=crop&q=80&w=200'),
        ('Beverages', 'beverages', 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=200'),
        ('Snacks', 'snacks', 'https://images.unsplash.com/photo-1599490659213-e2b9527b0876?auto=format&fit=crop&q=80&w=200');
      `;
      await client.query(seedQuery);
      console.log('Default categories seeded.');
    } else {
      // Patch existing null values
      const patchQuery = `
        UPDATE categories SET image_url = CASE
          WHEN name = 'Fruits' THEN 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Vegetables' THEN 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Dairy & Eggs' THEN 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Bakery' THEN 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Meat & Seafood' THEN 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Pantry Staples' THEN 'https://images.unsplash.com/photo-1549203396-abae8a36a77b?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Beverages' THEN 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=200'
          WHEN name = 'Snacks' THEN 'https://images.unsplash.com/photo-1599490659213-e2b9527b0876?auto=format&fit=crop&q=80&w=200'
          ELSE image_url
        END
        WHERE image_url IS NULL;
      `;
      await client.query(patchQuery);
      console.log('Default categories image patched for existing rows.');
    }

    // 5.5 Seed default products if not already present
    const checkBananas = await client.query("SELECT COUNT(*) FROM products WHERE title = 'Organic Bananas';");
    if (parseInt(checkBananas.rows[0].count, 10) === 0) {
      console.log('Seeding default products...');
      const catsRes = await client.query('SELECT id, name FROM categories;');
      const catIdMap = {};
      catsRes.rows.forEach(r => {
        catIdMap[r.name] = r.id;
      });

      const seedProductsQuery = `
        INSERT INTO products (category_id, title, price, unit, stock_quantity, image_url, is_available) VALUES
        ($1, 'Organic Bananas', 2.99, '1 kg bag', 45, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=200', true),
        ($2, 'Fresh Whole Milk', 3.49, '1 gal jug', 24, 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=200', true),
        ($3, 'Artisanal Sourdough Bread', 4.50, 'each', 15, 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?auto=format&fit=crop&q=80&w=200', true),
        ($4, 'Atlantic Salmon Fillet', 18.99, '500g', 8, 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&q=80&w=200', true),
        ($5, 'Extra Virgin Olive Oil', 12.99, '750ml bottle', 14, 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&q=80&w=200', true),
        ($6, 'Sparkling Water Lime', 3.99, '12 x 355ml pack', 32, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=200', true);
      `;

      await client.query(seedProductsQuery, [
        catIdMap['Fruits'] || 1,
        catIdMap['Dairy & Eggs'] || 3,
        catIdMap['Bakery'] || 4,
        catIdMap['Meat & Seafood'] || 5,
        catIdMap['Pantry Staples'] || 6,
        catIdMap['Beverages'] || 7
      ]);
      console.log('Default products seeded successfully.');
    }

    // 6. Clean up temporary blob image URLs in products table to prevent console ERR_FILE_NOT_FOUND errors on frontend reload
    const cleanBlobImagesQuery = `
      UPDATE products 
      SET image_url = 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=400' 
      WHERE image_url LIKE 'blob:%';
    `;
    await client.query(cleanBlobImagesQuery);
    console.log('Temporary blob URLs cleaned up in products table.');

    await client.query('COMMIT');
    console.log('Database initialization completed successfully.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error during database initialization/migrations. Rolled back.', error);
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  initializeDatabase
};
