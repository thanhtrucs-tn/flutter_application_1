const BaseRepository = require('./base.repository');
const { Device } = require('../models');

/**
 * Repository for Device model.
 */
class DeviceRepository extends BaseRepository {
  constructor() {
    super(Device);
  }

  async findByElderlyId(elderlyId) {
    return this.model.findOne({ where: { elderlyId } });
  }

  async findBySerialNumber(serialNumber) {
    return this.model.findOne({ where: { serialNumber } });
  }

  async findOrCreateByElderlyId(elderlyId, defaults = {}) {
    const [device, created] = await this.model.findOrCreate({
      where: { elderlyId },
      defaults: {
        elderlyName: defaults.elderlyName || elderlyId,
        status: 'active',
        ...defaults,
      },
    });
    return { device, created };
  }

  async touchLastSeen(id, timestamp) {
    return this.update(id, { lastSeenAt: timestamp });
  }
}

module.exports = new DeviceRepository();
