const winston = require('winston');
const path = require('path');
require('winston-daily-rotate-file');

const env = require('../config/env.config');

const { combine, timestamp, printf, colorize, errors } = winston.format;

/**
 * Custom log format that includes timestamp, level, message, and
 * stack trace when available.
 */
const logFormat = printf(({ level, message, timestamp: ts, stack }) => {
  return `${ts} [${level}]: ${stack || message}`;
});

const transports = [
  new winston.transports.Console({
    format: combine(
      colorize(),
      timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
      errors({ stack: true }),
      logFormat,
    ),
  }),
];

if (env.logToFile) {
  /**
   * Daily rotate file transport for persisted logs. Disabled in fast-dev
   * mode to avoid disk I/O blocking startup on simulation restarts.
   */
  transports.push(
    new winston.transports.DailyRotateFile({
      filename: path.join(process.cwd(), 'logs', 'application-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '14d',
      level: env.logLevel,
    }),
  );
}

const logger = winston.createLogger({
  level: env.logLevel,
  defaultMeta: { service: 'sos-care-backend' },
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    errors({ stack: true }),
    logFormat,
  ),
  transports,
});

module.exports = logger;
