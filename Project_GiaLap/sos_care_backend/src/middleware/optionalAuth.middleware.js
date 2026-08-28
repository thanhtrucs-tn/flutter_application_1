const jwt = require('jsonwebtoken');
const env = require('../config/env.config');

/**
 * Middleware "auth tùy chọn": nếu có Bearer token HỢP LỆ thì set req.user,
 * còn không thì vẫn cho đi tiếp (endpoint public). Dùng cho các route đọc
 * thông tin user — client không bắt buộc phải đăng nhập.
 */
const optionalAuthMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      req.user = jwt.verify(authHeader.split(' ')[1], env.jwt.secret);
    } catch (err) {
      // Token hết hạn/không hợp lệ → coi như chưa đăng nhập, không chặn.
    }
  }
  next();
};

module.exports = optionalAuthMiddleware;