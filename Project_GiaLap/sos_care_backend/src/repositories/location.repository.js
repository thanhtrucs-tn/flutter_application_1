const BaseRepository = require('./base.repository');
const { Location } = require('../models');

class LocationRepository extends BaseRepository {
  constructor() {
    super(Location);
  }

  async findByDeviceId(deviceId, options = {}) {
    return this.model.findAll({
      where: { deviceId },
      order: [['timestamp', 'DESC']],
      ...options,
    });
  }
}

module.exports = new LocationRepository();
