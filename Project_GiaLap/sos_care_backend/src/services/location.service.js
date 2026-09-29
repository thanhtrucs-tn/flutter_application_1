const locationRepository = require('../repositories/location.repository');
const deviceRepository = require('../repositories/device.repository');
const relativeRepository = require('../repositories/relative.repository');
const alertService = require('./alert.service');

/**
 * Service for storing GPS location updates from devices. Emits a scoped
 * `device:location` event.
 *
 * Leaving home no longer raises an alert (product decision): the relative's
 * home (safe_zone_lat/lng) is only drawn on the map. Alerts for dangerous
 * places will come from a dedicated danger-zone service.
 */
class LocationService {
  async create(payload) {
    const { deviceId, elderlyId, timestamp, latitude, longitude } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    const location = await locationRepository.create({
      deviceId: device.id,
      latitude,
      longitude,
      timestamp: new Date(timestamp),
    });

    const relative = device.elderlyId
      ? await relativeRepository.findByDeviceElderlyId(device.elderlyId)
      : null;

    const realtimePayload = {
      id: location.id,
      relativeId: relative ? relative.id : null,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      latitude: parseFloat(location.latitude),
      longitude: parseFloat(location.longitude),
      timestamp: location.timestamp,
      createdAt: location.createdAt,
    };

    alertService.emitCaregiverEvent('device:location', realtimePayload, relative ? relative.userId : null);

    return location;
  }

  async listByDevice(deviceId, pagination) {
    return locationRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new LocationService();