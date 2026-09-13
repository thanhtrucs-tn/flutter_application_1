const morgan = require('morgan');
const env = require('../config/env.config');
const logger = require('../utils/logger.util');

/**
 * Morgan middleware that writes HTTP access logs through winston.
 *
 * Chỉ log đường dẫn (pathname), không log query string — tránh ghi token
 * Socket.IO (gửi qua ?token= trong URL polling) vào file log.
 */
morgan.token('pathname', (req) => {
  const queryIndex = req.originalUrl.indexOf('?');
  return queryIndex === -1 ? req.originalUrl : req.originalUrl.slice(0, queryIndex);
});

const morganFormat = env.nodeEnv === 'production'
  ? ':remote-addr - :method :pathname :status :res[content-length] - :response-time ms'
  : ':method :pathname :status - :response-time ms';

const loggerMiddleware = morgan(morganFormat, {
  stream: {
    write: (message) => logger.info(message.trim()),
  },
});

module.exports = loggerMiddleware;
