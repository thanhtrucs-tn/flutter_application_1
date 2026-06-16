const morgan = require('morgan');
const env = require('../config/env.config');
const logger = require('../utils/logger.util');

/**
 * Morgan middleware that writes HTTP access logs through winston.
 */
const morganFormat = env.nodeEnv === 'production'
  ? ':remote-addr - :method :url :status :res[content-length] - :response-time ms'
  : 'dev';

const loggerMiddleware = morgan(morganFormat, {
  stream: {
    write: (message) => logger.info(message.trim()),
  },
});

module.exports = loggerMiddleware;
