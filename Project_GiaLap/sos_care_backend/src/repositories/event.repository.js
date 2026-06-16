const BaseRepository = require('./base.repository');
const { Event } = require('../models');

class EventRepository extends BaseRepository {
  constructor() {
    super(Event);
  }

  async findByDeviceId(deviceId, options = {}) {
    return this.model.findAll({
      where: { deviceId },
      order: [['timestamp', 'DESC']],
      ...options,
    });
  }
}

module.exports = new EventRepository();
