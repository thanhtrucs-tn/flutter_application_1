const AppError = require('../utils/appError.util');
const env = require('../config/env.config');
const response = require('../utils/response.util');
const logger = require('../utils/logger.util');
const multer = require('multer');

/**
 * Central Express error handler.
 *
 * Logs the error and returns a sanitized JSON response. Operational
 * errors (AppError) expose their status code and message; unexpected
 * errors return 500 with a generic message in production.
 */
// eslint-disable-next-line no-unused-vars
const errorMiddleware = (err, req, res, next) => {
  logger.error(err);

  if (err instanceof AppError) {
    return response.error(res, err.message, err.statusCode, err.errors);
  }

  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return response.error(res, 'Ảnh vượt quá giới hạn 5MB', 400);
    }
    if (err.code === 'UNSUPPORTED_FILE_TYPE') {
      return response.error(res, 'Tệp tải lên không phải là ảnh', 400);
    }
    return response.error(res, 'Tệp tải lên không hợp lệ', 400);
  }

  if (err.name === 'SequelizeValidationError' || err.name === 'SequelizeUniqueConstraintError') {
    const errors = err.errors.map((e) => ({ field: e.path, message: e.message }));
    return response.error(res, 'Lỗi cơ sở dữ liệu', 400, errors);
  }

  if (err.name === 'JsonWebTokenError') {
    return response.error(res, 'Token không hợp lệ', 401);
  }

  const message = env.nodeEnv === 'production'
    ? 'Đã xảy ra lỗi không mong muốn'
    : err.message;

  return response.error(res, message, 500);
};

module.exports = errorMiddleware;
