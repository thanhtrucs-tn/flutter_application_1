const deviceStatusRepository = require('../repositories/deviceStatus.repository');
const deviceRepository = require('../repositories/device.repository');
const socketService = require('./socket.service');

/**
 * Service for storing battery, heart rate, and online/offline status
 * updates. Keeps the device `lastSeenAt` timestamp fresh.
 */
class DeviceStatusService {
  async create(payload) {
    const {
      deviceId,
      elderlyId,
      timestamp,
      batteryPercent,
      heartRateBpm,
      isOnline,
    } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    const status = await deviceStatusRepository.create({
      deviceId: device.id,
      batteryPercent,
      heartRateBpm: heartRateBpm ?? null,
      isOnline: isOnline ?? true,
      timestamp: new Date(timestamp),
    });

    socketService.emit('device:status', {
      id: status.id,
      deviceId: device.id,
      elderlyId: device.elderlyId,
      batteryPercent: status.batteryPercent,
      heartRateBpm: status.heartRateBpm,
      isOnline: status.isOnline,
      timestamp: status.timestamp,
      createdAt: status.createdAt,
    });

    return status;
  }

  async getLatest(deviceId) {
    return deviceStatusRepository.findLatestByDeviceId(deviceId);
  }
}

module.exports = new DeviceStatusService();
