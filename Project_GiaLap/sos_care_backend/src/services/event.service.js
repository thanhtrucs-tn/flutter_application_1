const eventRepository = require('../repositories/event.repository');
const deviceRepository = require('../repositories/device.repository');
const alertService = require('./alert.service');

/**
 * Service for handling device events (fall, heart rate, SpO2). Persists the raw
 * event, derives a caregiver-facing alert, and broadcasts a scoped realtime
 * event to the owning caregiver's room.
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

    const mapping = this._mapType(type, device);
    let caregiverAlert = null;
    let relative = null;
    if (mapping) {
      const result = await alertService.createFromDeviceEvent({
        device,
        type: mapping.alertType,
        urgency: mapping.urgency,
        message: mapping.message,
        latitude,
        longitude,
        timestamp,
        sourceType: 'event',
        sourceId: event.id,
      });
      caregiverAlert = result.alert;
      relative = result.relative;
    }

    const realtimePayload = {
      id: event.id,
      alertId: caregiverAlert ? caregiverAlert.id : null,
      relativeId: relative ? relative.id : null,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      type: event.type,
      latitude: parseFloat(event.latitude),
      longitude: parseFloat(event.longitude),
      timestamp: event.timestamp,
      createdAt: event.createdAt,
    };

    if (mapping && mapping.eventName) {
      alertService.emitCaregiverEvent(mapping.eventName, realtimePayload, relative ? relative.userId : null);
    }

    return event;
  }

  // Map a device event type to a caregiver alert type + realtime event name.
  _mapType(type, device) {
    const who = device.elderlyName || device.elderlyId;
    switch (type) {
      case 'FALL_DETECTED':
        return { alertType: 'fall', urgency: 'critical', eventName: 'event:fall', message: `Phát hiện té ngã: ${who}` };
      case 'HEART_RATE_ALERT':
        return { alertType: 'vital', urgency: 'warning', eventName: 'event:heart_rate', message: `Nhịp tim bất thường: ${who}` };
      case 'SPO2_ALERT':
        return { alertType: 'vital', urgency: 'warning', eventName: 'event:heart_rate', message: `SpO2 bất thường: ${who}` };
      default:
        return null;
    }
  }

  async listByDevice(deviceId, pagination) {
    return eventRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new EventService();