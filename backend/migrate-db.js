const { Client } = require('pg');
require('dotenv').config();

async function migrate() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('Connected to Neon PostgreSQL.');

    // 1. Alter orders table to add cancel_reason
    console.log('Adding cancel_reason column to orders if not exists...');
    await client.query(`
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancel_reason TEXT;
    `);
    console.log('cancel_reason column verified.');

    // 2. Fetch column names to confirm
    const res = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'orders';
    `);
    console.log('Current orders columns:');
    res.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type}`);
    });

  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await client.end();
  }
}

migrate();
