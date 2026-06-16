const http = require('http');
const { Server } = require('socket.io');

const env = require('./config/env.config');
const sequelize = require('./config/database');
const createApp = require('./app');
const setupSocketHandlers = require('./socket/socket.handler');
const socketService = require('./services/socket.service');
const logger = require('./utils/logger.util');

const startServer = async () => {
  try {
    const dbStart = Date.now();
    await sequelize.authenticate();
    logger.info(`Kết nối cơ sở dữ liệu thành công trong ${Date.now() - dbStart}ms.`);

    if (env.dbSync && env.nodeEnv !== 'production') {
      const syncStart = Date.now();
      await sequelize.sync({ alter: true });
      logger.info(`Đã đồng bộ hóa các model Sequelize (alter) trong ${Date.now() - syncStart}ms.`);
    } else {
      if (env.dbSync && env.nodeEnv === 'production') {
        logger.warn('DB_SYNC=true bị bỏ qua trong môi trường production để tránh mất dữ liệu.');
      } else {
        logger.info('Bỏ qua đồng bộ hóa model (DB_SYNC=false).');
      }
    }

    const app = createApp();
    const server = http.createServer(app);

    const io = new Server(server, {
      cors: {
        origin: env.corsOrigin === '*' ? '*' : env.corsOrigin.split(','),
        methods: ['GET', 'POST'],
      },
    });

    socketService.setInstance(io);
    setupSocketHandlers(io);

    server.listen(env.port, () => {
      logger.info(`SOS Care backend đang chạy tại http://localhost:${env.port}`);
    });

    const gracefulShutdown = async (signal) => {
      logger.info(`Nhận tín hiệu ${signal}, đang tắt server...`);
      server.close(async () => {
        io.close();
        await sequelize.close();
        logger.info('Đã đóng kết nối. Thoát.');
        process.exit(0);
      });
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  } catch (err) {
    logger.error('Không thể khởi động server:', err);
    process.exit(1);
  }
};

startServer();
