const sosAlertRepository = require('../repositories/sosAlert.repository');
const deviceRepository = require('../repositories/device.repository');
const socketService = require('./socket.service');
const AppError = require('../utils/appError.util');

/**
 * Service for handling SOS emergency alerts.
 *
 * Persists the alert and broadcasts a realtime `sos:alert` event to
 * all connected SOS Care clients.
 */
class SosService {
  async create(payload) {
    const { deviceId, elderlyId, timestamp, latitude, longitude, type } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    const alert = await sosAlertRepository.create({
      deviceId: device.id,
      type: type || 'SOS',
      latitude,
      longitude,
      timestamp: new Date(timestamp),
      status: 'pending',
      payloadJson: payload,
    });

    const realtimePayload = {
      id: alert.id,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      type: alert.type,
      latitude: parseFloat(alert.latitude),
      longitude: parseFloat(alert.longitude),
      timestamp: alert.timestamp,
      status: alert.status,
      createdAt: alert.createdAt,
    };

    socketService.emit('sos:alert', realtimePayload);

    return alert;
  }

  async listByDevice(deviceId, pagination) {
    return sosAlertRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new SosService();
