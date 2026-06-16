/**
 * Operational error class used to distinguish expected application
 * errors from unexpected programming errors.
 *
 * Instances of AppError are safe to expose to clients with the provided
 * statusCode and message; other errors are sanitized by the central
 * error handler.
 */
class AppError extends Error {
  constructor(message, statusCode = 500, errors = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    this.errors = errors;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
