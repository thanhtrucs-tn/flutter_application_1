const locationRepository = require('../repositories/location.repository');
const deviceRepository = require('../repositories/device.repository');
const socketService = require('./socket.service');

/**
 * Service for storing GPS location updates from devices.
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

    socketService.emit('device:location', {
      id: location.id,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      latitude: parseFloat(location.latitude),
      longitude: parseFloat(location.longitude),
      timestamp: location.timestamp,
      createdAt: location.createdAt,
    });

    return location;
  }

  async listByDevice(deviceId, pagination) {
    return locationRepository.findByDeviceId(deviceId, pagination);
  }
}

module.exports = new LocationService();
