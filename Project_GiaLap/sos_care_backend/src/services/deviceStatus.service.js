const deviceStatusRepository = require('../repositories/deviceStatus.repository');
const deviceRepository = require('../repositories/device.repository');
const relativeRepository = require('../repositories/relative.repository');
const alertService = require('./alert.service');

/**
 * Service for storing battery, heart rate, SpO2, and online/offline status
 * updates. Keeps the device `lastSeenAt` fresh and emits a scoped
 * `device:status` event to the owning caregiver's room.
 */
class DeviceStatusService {
  async create(payload) {
    const {
      deviceId,
      elderlyId,
      timestamp,
      batteryPercent,
      heartRateBpm,
      spo2Percent,
      isOnline,
    } = payload;

    const { device } = await deviceRepository.findOrCreateByElderlyId(
      elderlyId || deviceId,
      { elderlyName: elderlyId },
    );

    await deviceRepository.touchLastSeen(device.id, new Date(timestamp));

    // Preserve the last known online/offline state when the caller omits isOnline
    // (e.g. a battery-only update from the simulator) so an offline device is not
    // flipped back online. Defaults to online only when no prior status exists
    // (first telemetry for the device).
    let effectiveIsOnline = isOnline;
    if (effectiveIsOnline === undefined || effectiveIsOnline === null) {
      const latest = await deviceStatusRepository.findLatestByDeviceId(device.id);
      effectiveIsOnline = latest ? latest.isOnline : true;
    }

    const status = await deviceStatusRepository.create({
      deviceId: device.id,
      batteryPercent,
      heartRateBpm: heartRateBpm ?? null,
      spo2Percent: spo2Percent ?? null,
      isOnline: effectiveIsOnline,
      timestamp: new Date(timestamp),
    });

    const relative = device.elderlyId
      ? await relativeRepository.findByDeviceElderlyId(device.elderlyId)
      : null;

    alertService.emitCaregiverEvent(
      'device:status',
      {
        id: status.id,
        relativeId: relative ? relative.id : null,
        deviceId: device.id,
        elderlyId: device.elderlyId,
        batteryPercent: status.batteryPercent,
        heartRateBpm: status.heartRateBpm,
        spo2Percent: status.spo2Percent,
        isOnline: status.isOnline,
        timestamp: status.timestamp,
        createdAt: status.createdAt,
      },
      relative ? relative.userId : null,
    );

    return status;
  }

  async getLatest(deviceId) {
    return deviceStatusRepository.findLatestByDeviceId(deviceId);
  }
}

module.exports = new DeviceStatusService();