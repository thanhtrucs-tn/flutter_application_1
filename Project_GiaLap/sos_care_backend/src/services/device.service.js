const { Device, DeviceStatus } = require('../models');
const deviceStatusRepository = require('../repositories/device_status.repository');
const AppError = require('../utils/app_error.util');

/**
 * Service for retrieving device details and latest status.
 */
class DeviceService {
  async getById(id, userId) {
    // Chỉ trả thiết bị thuộc người dùng hiện tại — chặn đọc thiết bị của người khác.
    const device = await Device.findOne({
      where: { id, userId },
      include: [
        {
          model: DeviceStatus,
          as: 'statuses',
          limit: 1,
          order: [['timestamp', 'DESC']],
        },
      ],
    });

    if (!device) {
      throw new AppError('Không tìm thấy thiết bị', 404);
    }

    const latestStatus = await deviceStatusRepository.findLatestByDeviceId(id);

    return {
      ...device.toJSON(),
      latestStatus: latestStatus ? latestStatus.toJSON() : null,
    };
  }
}

module.exports = new DeviceService();
