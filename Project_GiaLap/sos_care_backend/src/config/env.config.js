require('dotenv').config();

/**
 * Centralized environment configuration.
 *
 * Reads values from process.env and provides sensible defaults so the
 * rest of the application does not scatter env access.
 */
const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '8080', 10),
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    name: process.env.DB_NAME || 'sos_care_db',
    user: process.env.DB_USER || 'root',
    pass: process.env.DB_PASS || '',
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  logLevel: process.env.LOG_LEVEL || 'info',
  logToFile: process.env.LOG_TO_FILE !== 'false',
  dbSync: process.env.DB_SYNC === 'true',
  deviceAuthMode: process.env.DEVICE_AUTH_MODE || 'none',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  deviceToken: process.env.DEVICE_TOKEN,
};

if (!env.jwt.secret) {
  throw new Error('JWT_SECRET is required. Please set it in .env file.');
}

module.exports = env;
