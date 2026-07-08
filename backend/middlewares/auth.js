const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'grocery-app-super-secret-jwt-key';

/**
 * Middleware to enforce admin-only authorization.
 * Inspects Authorization header (Bearer token) or custom X-Admin-Token header.
 */
const adminAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const adminHeaderToken = req.headers['x-admin-token'];

  // Default to a fallback token if ADMIN_API_KEY is not defined in env
  const expectedToken = process.env.ADMIN_API_KEY || 'admin-secret-token';

  const isAuthorized =
    (authHeader && authHeader === `Bearer ${expectedToken}`) ||
    (adminHeaderToken && adminHeaderToken === expectedToken);

  if (!isAuthorized) {
    const error = new Error('Unauthorized - Admin privileges required');
    error.statusCode = 401;
    return next(error);
  }

  next();
};

/**
 * Middleware to authenticate standard mobile client JWT tokens.
 */
const authenticateUser = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    const error = new Error('Unauthorized - Token is missing or invalid');
    error.statusCode = 401;
    return next(error);
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // Contains user id and phoneNumber
    next();
  } catch (err) {
    const error = new Error('Unauthorized - Token verification failed');
    error.statusCode = 401;
    return next(error);
  }
};

module.exports = {
  adminAuth,
  authenticateUser
};
