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

module.exports = {
  adminAuth
};
