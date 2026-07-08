const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('DATABASE_URL is not defined in the environment variables.');
  process.exit(1);
}

// Neon DB typically requires SSL. We enable SSL by default, unless connecting to localhost.
const isLocalhost = connectionString.includes('localhost') || connectionString.includes('127.0.0.1');

const poolConfig = {
  connectionString,
  ssl: isLocalhost ? false : { rejectUnauthorized: false }
};

const pool = new Pool(poolConfig);

pool.on('connect', () => {
  console.log('Database pool connected successfully.');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle database client:', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
