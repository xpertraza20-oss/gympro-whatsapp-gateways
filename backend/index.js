// Load environment variables as the very first step
require('dotenv').config();

const app = require('./app');
const { initializeDatabase } = require('./models/dbInit');
const { pool } = require('./config/db');

const PORT = process.env.PORT || 5000;

/**
 * Starts the application server.
 * Connects to the database, runs schema migrations, and begins listening on the port.
 */
async function startServer() {
  try {
    // 1. Verify connection and run table migrations
    console.log('Verifying database connection...');
    await pool.query('SELECT 1;');
    console.log('Database connection verified successfully.');

    await initializeDatabase();

    // 2. Start Express app listening
    app.listen(PORT, () => {
      console.log('=====================================================');
      console.log(`🚀 Server started successfully!`);
      console.log(`🌍 Mode: ${process.env.NODE_ENV || 'development'}`);
      console.log(`📡 Port: ${PORT}`);
      console.log(`🔍 Health Check URL: http://localhost:${PORT}/api/health`);
      console.log('=====================================================');
    });
  } catch (error) {
    console.error('❌ Fatal error during server startup:', error);
    // Ensure database pool is drained on startup failure
    try {
      await pool.end();
    } catch (closeError) {
      console.error('Error closing database pool:', closeError);
    }
    process.exit(1);
  }
}

// Graceful shutdown handling
const gracefulShutdown = async (signal) => {
  console.log(`\nReceived ${signal}. Starting graceful shutdown...`);
  try {
    await pool.end();
    console.log('Database pool closed.');
    process.exit(0);
  } catch (error) {
    console.error('Error during database pool cleanup:', error);
    process.exit(1);
  }
};

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

startServer();
