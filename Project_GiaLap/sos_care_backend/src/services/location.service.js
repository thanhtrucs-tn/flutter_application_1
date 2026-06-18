const locationRepository = require('../repositories/location.repository');
const deviceRepository = require('../repositories/device.repository');
const relativeRepository = require('../repositories/relative.repository');
const alertService = require('./alert.service');
const geofenceService = require('./geofence.service');

/**
 * Service for storing GPS location updates from devices and computing
 * geofence breaches. Emits a scoped `device:location` event and, when the
 * device leaves a relative's safe zone, a `geofence:alert` event.
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

    const geofenceAlert = relative
      ? await geofenceService.checkBreach({ relative, latitude, longitude, timestamp })
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

    if (geofenceAlert && relative) {
      alertService.emitCaregiverEvent(
        'geofence:alert',
        {
          alertId: geofenceAlert.id,
          relativeId: relative.id,
          deviceId: device.id,
          elderlyId: device.elderlyId,
          latitude: parseFloat(geofenceAlert.latitude),
          longitude: parseFloat(geofenceAlert.longitude),
          message: geofenceAlert.message,
          timestamp: geofenceAlert.timestamp,
          createdAt: geofenceAlert.createdAt,
        },
        relative.userId,
      );
    }

    return location;
  }

  async listByDevice(deviceId, pagination) {
    return locationRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new LocationService();