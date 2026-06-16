const eventRepository = require('../repositories/event.repository');
const deviceRepository = require('../repositories/device.repository');
const socketService = require('./socket.service');

/**
 * Service for handling device events such as fall detection and
 * heart rate alerts. Emits realtime notifications for critical events.
 */
class EventService {
  async create(payload) {
    const { deviceId, elderlyId, timestamp, latitude, longitude, type } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    const event = await eventRepository.create({
      deviceId: device.id,
      type,
      latitude,
      longitude,
      timestamp: new Date(timestamp),
      payloadJson: payload,
    });

    const realtimePayload = {
      id: event.id,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      type: event.type,
      latitude: parseFloat(event.latitude),
      longitude: parseFloat(event.longitude),
      timestamp: event.timestamp,
      createdAt: event.createdAt,
    };

    if (type === 'FALL_DETECTED') {
      socketService.emit('event:fall', realtimePayload);
    } else if (type === 'HEART_RATE_ALERT') {
      socketService.emit('event:heart_rate', realtimePayload);
    }

    return event;
  }

  async listByDevice(deviceId, pagination) {
    return eventRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new EventService();
