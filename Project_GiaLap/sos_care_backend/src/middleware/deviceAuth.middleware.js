const env = require('../config/env.config');
const response = require('../utils/response.util');

/**
 * Optional lightweight device authentication for simulator POST endpoints.
 *
 * When `DEVICE_AUTH_MODE=token`, the request must include the header
 * `X-Device-Token` matching `DEVICE_TOKEN` from environment. In local
 * development `DEVICE_AUTH_MODE=none` skips this check.
 */
const deviceAuthMiddleware = (req, res, next) => {
  if (env.deviceAuthMode !== 'token') {
    return next();
  }

  const token = req.headers['x-device-token'];
  if (!token || token !== env.deviceToken) {
    return response.error(res, 'Thiếu hoặc sai thiết bị token', 403);
  }

  next();
};

module.exports = deviceAuthMiddleware;
