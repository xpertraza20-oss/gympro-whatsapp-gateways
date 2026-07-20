const { Pool } = require('pg');
require('dotenv').config({ path: '../backend/.env' });

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error("No DATABASE_URL found.");
  process.exit(1);
}

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    const tablesRes = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    console.log("TABLES IN DATABASE:");
    console.log(tablesRes.rows.map(r => r.table_name));

    for (const row of tablesRes.rows) {
      const tableName = row.table_name;
      const colsRes = await pool.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = $1;
      `, [tableName]);
      console.log(`\nColumns for table "${tableName}":`);
      colsRes.rows.forEach(col => {
        console.log(`  - ${col.column_name} (${col.data_type}, nullable: ${col.is_nullable})`);
      });
    }

  } catch (err) {
    console.error("Error checking schema:", err);
  } finally {
    await pool.end();
  }
}

run();
