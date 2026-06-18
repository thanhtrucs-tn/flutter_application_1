const logger = require('../utils/logger.util');
const jwt = require('jsonwebtoken');
const env = require('../config/env.config');

const userRoom = (id) => `user:${id}`;

/**
 * Configures Socket.IO connection handlers.
 *
 * Authenticates each socket via the JWT sent in the handshake (auth.token, the
 * Authorization header, or a ?token= query param) and joins the caregiver's
 * `user:<id>` room so realtime events can be scoped per account. Connections
 * without a valid token are allowed but join no user room, so they receive no
 * scoped caregiver events.
 */
const setupSocketHandlers = (io) => {
  io.use((socket, next) => {
    const token =
      (socket.handshake.auth && socket.handshake.auth.token) ||
      (socket.handshake.headers.authorization || '').replace(/^Bearer\s+/i, '') ||
      socket.handshake.query.token;
    if (!token) {
      return next();
    }
    try {
      socket.data.user = jwt.verify(token, env.jwt.secret);
    } catch (err) {
      // Invalid token: connect but join no room.
    }
    next();
  });

  io.on('connection', (socket) => {
    const user = socket.data.user;
    if (user && user.id) {
      socket.join(userRoom(user.id));
      logger.info(`Socket ${socket.id} joined room ${userRoom(user.id)}`);
    } else {
      logger.info(`Socket connected (unauthenticated): ${socket.id}`);
    }

    socket.on('subscribe', (room) => {
      // Only allow subscribing to the socket's own user room.
      if (user && room === userRoom(user.id)) {
        socket.join(room);
        logger.info(`Socket ${socket.id} joined room ${room}`);
      }
    });

    socket.on('disconnect', () => {
      logger.info(`Socket disconnected: ${socket.id}`);
    });
  });
};

module.exports = setupSocketHandlers;