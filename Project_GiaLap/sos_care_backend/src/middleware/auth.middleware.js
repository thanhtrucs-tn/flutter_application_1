const jwt = require('jsonwebtoken');
const env = require('../config/env.config');
const response = require('../utils/response.util');

/**
 * Verifies the JWT Bearer token in the Authorization header.
 *
 * Attach decoded user payload to `req.user` on success. Returns 401
 * when the token is missing or invalid.
 */
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return response.error(res, 'Thiếu token xác thực', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.jwt.secret);
    req.user = decoded;
    next();
  } catch (err) {
    return response.error(res, 'Token không hợp lệ hoặc đã hết hạn', 401);
  }
};

module.exports = authMiddleware;
