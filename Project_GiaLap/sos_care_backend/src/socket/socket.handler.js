const logger = require('../utils/logger.util');

/**
 * Configures Socket.IO connection handlers.
 *
 * Currently accepts all connections from the SOS Care app and logs
 * connect/disconnect events. Room-based subscriptions can be added
 * here when the app needs to filter by device or user.
 */
const setupSocketHandlers = (io) => {
  io.on('connection', (socket) => {
    logger.info(`Socket connected: ${socket.id}`);

    socket.on('subscribe', (room) => {
      socket.join(room);
      logger.info(`Socket ${socket.id} joined room ${room}`);
    });

    socket.on('disconnect', () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });
};

module.exports = setupSocketHandlers;
