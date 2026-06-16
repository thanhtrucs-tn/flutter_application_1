const { Sequelize } = require('sequelize');
const env = require('./env.config');
const logger = require('../utils/logger.util');

const sequelize = new Sequelize(
  env.db.name,
  env.db.user,
  env.db.pass,
  {
    host: env.db.host,
    port: env.db.port,
    dialect: 'mysql',
    logging: env.nodeEnv === 'development'
      ? (msg) => logger.debug(msg)
      : false,
    pool: {
      max: env.nodeEnv === 'production' ? 10 : 5,
      min: 0,
      acquire: 15000,
      idle: 5000,
      evict: 3000,
    },
    dialectOptions: {
      connectTimeout: 10000,
    },
    define: {
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci',
      timestamps: true,
      paranoid: true,
      underscored: true,
    },
  },
);

module.exports = sequelize;
