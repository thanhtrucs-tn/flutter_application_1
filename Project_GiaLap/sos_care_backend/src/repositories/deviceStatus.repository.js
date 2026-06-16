const BaseRepository = require('./base.repository');
const { DeviceStatus } = require('../models');

class DeviceStatusRepository extends BaseRepository {
  constructor() {
    super(DeviceStatus);
  }

  async findLatestByDeviceId(deviceId) {
    return this.model.findOne({
      where: { deviceId },
      order: [['timestamp', 'DESC']],
    });
  }
}

module.exports = new DeviceStatusRepository();
