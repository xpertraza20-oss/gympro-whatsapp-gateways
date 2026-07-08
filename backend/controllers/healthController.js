const { pool } = require('../config/db');

/**
 * Basic server health check endpoint.
 * Returns information about uptime, memory usage, and platform.
 */
const getHealth = (req, res, next) => {
  try {
    const healthStatus = {
      status: 'UP',
      timestamp: new Date().toISOString(),
      uptime: `${Math.floor(process.uptime())} seconds`,
      memoryUsage: {
        rss: `${Math.round(process.memoryUsage().rss / 1024 / 1024 * 100) / 100} MB`,
        heapTotal: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024 * 100) / 100} MB`,
        heapUsed: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100} MB`
      },
      nodeVersion: process.version,
      platform: process.platform
    };
    res.status(200).json(healthStatus);
  } catch (error) {
    next(error);
  }
};

/**
 * Database health check endpoint.
 * Tests connection to the PostgreSQL database with a simple query.
 */
const getDbHealth = async (req, res, next) => {
  try {
    const startTime = Date.now();
    const result = await pool.query('SELECT NOW();');
    const latency = Date.now() - startTime;

    res.status(200).json({
      status: 'UP',
      database: 'PostgreSQL',
      connection: 'Healthy',
      latency: `${latency}ms`,
      dbTime: result.rows[0].now
    });
  } catch (error) {
    console.error('Database connection test failed:', error);
    res.status(503).json({
      status: 'DOWN',
      database: 'PostgreSQL',
      connection: 'Failed',
      error: error.message
    });
  }
};

module.exports = {
  getHealth,
  getDbHealth
};
