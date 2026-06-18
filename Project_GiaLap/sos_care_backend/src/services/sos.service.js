const sosAlertRepository = require('../repositories/sosAlert.repository');
const deviceRepository = require('../repositories/device.repository');
const alertService = require('./alert.service');

/**
 * Service for handling SOS emergency alerts.
 *
 * Persists the raw device SOS row, derives a caregiver-facing alert (so the
 * Flutter app can list/acknowledge it), and broadcasts a scoped `sos:alert`
 * realtime event to the owning caregiver's room.
 */
class SosService {
  async create(payload) {
    const { deviceId, elderlyId, timestamp, latitude, longitude, type } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    const sosAlert = await sosAlertRepository.create({
      deviceId: device.id,
      type: type || 'SOS',
      latitude,
      longitude,
      timestamp: new Date(timestamp),
      status: 'pending',
      payloadJson: payload,
    });

    const { alert: caregiverAlert, relative } = await alertService.createFromDeviceEvent({
      device,
      type: 'sos',
      urgency: 'critical',
      message: `SOS khẩn cấp từ ${device.elderlyName || device.elderlyId}`,
      latitude,
      longitude,
      timestamp,
      sourceType: 'sos_alert',
      sourceId: sosAlert.id,
    });

    const realtimePayload = {
      id: sosAlert.id,
      alertId: caregiverAlert.id,
      relativeId: relative ? relative.id : null,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      type: sosAlert.type,
      latitude: parseFloat(sosAlert.latitude),
      longitude: parseFloat(sosAlert.longitude),
      timestamp: sosAlert.timestamp,
      status: sosAlert.status,
      createdAt: sosAlert.createdAt,
    };

    alertService.emitCaregiverEvent('sos:alert', realtimePayload, relative ? relative.userId : null);

    return sosAlert;
  }

  async listByDevice(deviceId, pagination) {
    return sosAlertRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new SosService();