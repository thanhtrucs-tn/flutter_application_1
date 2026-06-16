const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const env = require('./config/env.config');
const routes = require('./routes');
const errorMiddleware = require('./middleware/error.middleware');
const loggerMiddleware = require('./middleware/logger.middleware');

/**
 * Express application factory.
 *
 * Returns a configured Express app with security headers, CORS,
 * request logging, API routes, and centralized error handling.
 */
const createApp = () => {
  const app = express();

  app.use(helmet());
  app.use(cors({
    origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
    credentials: true,
  }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  app.use(loggerMiddleware);

  app.use('/', routes);
  app.use(errorMiddleware);

  return app;
};

module.exports = createApp;
