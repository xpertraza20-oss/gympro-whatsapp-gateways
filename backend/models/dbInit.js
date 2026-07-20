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

    // 2.1. Create users table (email-first design)
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(50),
        is_verified BOOLEAN DEFAULT false,
        phone_number VARCHAR(50),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await client.query(createUsersTable);
    console.log('Users table checked/created.');

    // 2.1.1 Add email, phone, password, location columns if this is an upgrade from phone-only schema
    const alterUsersAddEmail = `
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email') THEN
          ALTER TABLE users ADD COLUMN email VARCHAR(255) UNIQUE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
          ALTER TABLE users ADD COLUMN phone VARCHAR(50);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_verified') THEN
          ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT false;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='password') THEN
          ALTER TABLE users ADD COLUMN password VARCHAR(255);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='location') THEN
          ALTER TABLE users ADD COLUMN location VARCHAR(255);
        END IF;
      END
      $$;
    `;
    await client.query(alterUsersAddEmail);
    console.log('Users table schema migration completed.');

    // 2.1.1b Alter orders table to add cancel_reason, shop_id, rider_id columns if not exists
    const alterOrdersAddColumns = `
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='cancel_reason') THEN
          ALTER TABLE orders ADD COLUMN cancel_reason TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='shop_id') THEN
          ALTER TABLE orders ADD COLUMN shop_id INTEGER;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='rider_id') THEN
          ALTER TABLE orders ADD COLUMN rider_id INTEGER;
        END IF;
      END
      $$;
    `;
    await client.query(alterOrdersAddColumns);
    await client.query(`
      CREATE TABLE IF NOT EXISTS order_status_history (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL,
        changed_by VARCHAR(100) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Orders table verification columns and order_status_history checked/migrated.');

    // 2.1.2 Ensure the UNIQUE index on users.email exists
    // (ALTER TABLE ADD COLUMN doesn't add a constraint automatically on existing tables)
    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
    `);
    console.log('Users email unique index checked/created.');

    // 2.1.3 Drop NOT NULL constraint on phone_number (email is now the primary identity)
    // This is safe to run multiple times — ALTER COLUMN is idempotent for nullability.
    await client.query(`
      ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;
    `);
    console.log('Users phone_number NOT NULL constraint removed.');

    // 2.2. OTPs table — safe migration
    // If the old schema exists (phone_number as PRIMARY KEY), drop and recreate with new design.
    // OTPs are short-lived so data loss is acceptable; any pending OTPs expire in 5 min anyway.
    await client.query(`
      DO $$
      BEGIN
        -- Detect legacy schema: phone_number is the primary key column
        IF EXISTS (
          SELECT 1
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          WHERE tc.table_name   = 'otps'
            AND tc.constraint_type = 'PRIMARY KEY'
            AND kcu.column_name    = 'phone_number'
        ) THEN
          DROP TABLE otps;
        END IF;
      END
      $$;
    `);

    // Now create with the new schema (safe — no-op if already recreated)
    await client.query(`
      CREATE TABLE IF NOT EXISTS otps (
        id           SERIAL PRIMARY KEY,
        email        VARCHAR(255),
        phone_number VARCHAR(50),
        otp          VARCHAR(128) NOT NULL,
        expires_at   TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`ALTER TABLE otps ALTER COLUMN otp TYPE VARCHAR(128);`);
    console.log('OTPs table checked/migrated.');

    // 2.2.1 Indexes for fast lookups
    await client.query(`CREATE INDEX IF NOT EXISTS idx_otps_email  ON otps(email);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_otps_phone  ON otps(phone_number);`);
    console.log('OTPs table indexes checked/created.');

    // 2.3. Create orders table
    const createOrdersTable = `
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        delivery_address TEXT NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
        payment_method VARCHAR(50) DEFAULT 'COD',
        status VARCHAR(50) DEFAULT 'Pending',
        cancel_reason TEXT,
        items JSONB NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;
    await client.query(createOrdersTable);
    console.log('Orders table checked/created.');

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

    // 7. Alter shops and riders tables to add approval/verification columns if they do not exist
    const alterTablesQuery = `
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='shops') THEN
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='is_approved') THEN
            ALTER TABLE shops ADD COLUMN is_approved BOOLEAN DEFAULT false;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='approval_status') THEN
            ALTER TABLE shops ADD COLUMN approval_status VARCHAR(50) DEFAULT 'pending';
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='approved_by') THEN
            ALTER TABLE shops ADD COLUMN approved_by VARCHAR(255);
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='approved_at') THEN
            ALTER TABLE shops ADD COLUMN approved_at TIMESTAMP WITH TIME ZONE;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='rejection_reason') THEN
            ALTER TABLE shops ADD COLUMN rejection_reason TEXT;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='suspension_reason') THEN
            ALTER TABLE shops ADD COLUMN suspension_reason TEXT;
          END IF;
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='riders') THEN
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='riders' AND column_name='verification_status') THEN
            ALTER TABLE riders ADD COLUMN verification_status VARCHAR(50) DEFAULT 'pending';
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='riders' AND column_name='approved_by') THEN
            ALTER TABLE riders ADD COLUMN approved_by VARCHAR(255);
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='riders' AND column_name='approved_at') THEN
            ALTER TABLE riders ADD COLUMN approved_at TIMESTAMP WITH TIME ZONE;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='riders' AND column_name='rejection_reason') THEN
            ALTER TABLE riders ADD COLUMN rejection_reason TEXT;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='riders' AND column_name='suspension_reason') THEN
            ALTER TABLE riders ADD COLUMN suspension_reason TEXT;
          END IF;
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='products') THEN
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='approval_status') THEN
            ALTER TABLE products ADD COLUMN approval_status VARCHAR(50) DEFAULT 'approved';
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='approved_by') THEN
            ALTER TABLE products ADD COLUMN approved_by VARCHAR(255);
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='approved_at') THEN
            ALTER TABLE products ADD COLUMN approved_at TIMESTAMP WITH TIME ZONE;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='rejection_reason') THEN
            ALTER TABLE products ADD COLUMN rejection_reason TEXT;
          END IF;
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='products' AND column_name='shop_id') THEN
            ALTER TABLE products ADD COLUMN shop_id INTEGER;
          END IF;
        END IF;

        -- Add commission_percentage to shops table
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='shops') THEN
          IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='shops' AND column_name='commission_percentage') THEN
            ALTER TABLE shops ADD COLUMN commission_percentage DECIMAL(5, 2) DEFAULT NULL;
          END IF;
        END IF;
      END
      $$;
    `;
    await client.query(alterTablesQuery);
    console.log('Shops, Riders, and Products verification column migrations completed.');

    // Create Marketplace Financial Tables
    await client.query(`
      CREATE TABLE IF NOT EXISTS system_settings (
        key VARCHAR(255) PRIMARY KEY,
        value VARCHAR(255) NOT NULL
      );
    `);
    await client.query(`
      INSERT INTO system_settings (key, value) VALUES ('global_commission_percentage', '10.00') ON CONFLICT (key) DO NOTHING;
    `);
    await client.query(`
      CREATE TABLE IF NOT EXISTS commissions (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE UNIQUE,
        shop_id INTEGER,
        gross_sales DECIMAL(10, 2) NOT NULL,
        commission_percentage DECIMAL(5, 2) NOT NULL,
        commission_amount DECIMAL(10, 2) NOT NULL,
        shop_payable DECIMAL(10, 2) NOT NULL,
        refunded_amount DECIMAL(10, 2) DEFAULT 0.00,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`
      CREATE TABLE IF NOT EXISTS shop_settlements (
        id SERIAL PRIMARY KEY,
        shop_id INTEGER,
        sales_amount DECIMAL(10, 2) NOT NULL,
        commission_amount DECIMAL(10, 2) NOT NULL,
        payable_amount DECIMAL(10, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'unpaid',
        paid_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    await client.query(`
      CREATE TABLE IF NOT EXISTS rider_settlements (
        id SERIAL PRIMARY KEY,
        rider_id INTEGER,
        deliveries_count INTEGER NOT NULL DEFAULT 0,
        earnings_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        cod_collected DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
        status VARCHAR(50) DEFAULT 'pending',
        paid_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Marketplace Financial Tables checked/created.');

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
