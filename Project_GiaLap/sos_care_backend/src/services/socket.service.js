/**
 * Thin wrapper around the Socket.IO server instance.
 *
 * The instance is set once during server bootstrap and then used by
 * services to emit realtime events without importing the HTTP server
 * module directly.
 */
class SocketService {
  constructor() {
    this.io = null;
  }

  setInstance(io) {
    this.io = io;
  }

  emit(event, payload) {
    if (this.io) {
      this.io.emit(event, payload);
    }
  }

  emitToRoom(room, event, payload) {
    if (this.io) {
      this.io.to(room).emit(event, payload);
    }
  }
}

module.exports = new SocketService();
