/**
 * Unified JSON response helpers used by all controllers and middleware.
 *
 * Every API response follows the envelope:
 * { success: boolean, data?: any, message?: string, errors?: any[], meta?: any }
 */

const success = (res, data = null, message = 'Thành công', statusCode = 200, meta = null) => {
  const payload = {
    success: true,
    data,
    message,
    errors: null,
  };
  if (meta) {
    payload.meta = meta;
  }
  return res.status(statusCode).json(payload);
};

const error = (res, message = 'Đã xảy ra lỗi', statusCode = 500, errors = null) => {
  return res.status(statusCode).json({
    success: false,
    data: null,
    message,
    errors,
  });
};

module.exports = {
  success,
  error,
};
