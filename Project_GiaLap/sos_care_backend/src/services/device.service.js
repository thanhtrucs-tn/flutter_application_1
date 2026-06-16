const { Device, DeviceStatus } = require('../models');
const deviceStatusRepository = require('../repositories/deviceStatus.repository');
const AppError = require('../utils/appError.util');

/**
 * Service for retrieving device details and latest status.
 */
class DeviceService {
  async getById(id) {
    const device = await Device.findByPk(id, {
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
