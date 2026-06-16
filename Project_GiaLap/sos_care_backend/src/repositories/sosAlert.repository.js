const BaseRepository = require('./base.repository');
const { SosAlert } = require('../models');

class SosAlertRepository extends BaseRepository {
  constructor() {
    super(SosAlert);
  }

  async findByDeviceId(deviceId, options = {}) {
    return this.model.findAll({
      where: { deviceId },
      order: [['timestamp', 'DESC']],
      ...options,
    });
  }
}

module.exports = new SosAlertRepository();
