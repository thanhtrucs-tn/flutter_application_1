const BaseRepository = require('./base.repository');
const { Relative } = require('../models');

/**
 * Repository for the Relative model. Reads are scoped by the owning caregiver
 * so a user can never fetch another user's relative.
 */
class RelativeRepository extends BaseRepository {
  constructor() {
    super(Relative);
  }

  async findByUserId(userId) {
    return this.model.findAll({
      where: { userId },
      include: [{ association: 'contacts' }],
      order: [['created_at', 'ASC']],
    });
  }

  async findByIdForUser(id, userId) {
    return this.model.findOne({
      where: { id, userId },
      include: [{ association: 'contacts' }],
    });
  }

  async findByDeviceElderlyId(deviceElderlyId) {
    return this.model.findOne({ where: { deviceElderlyId } });
  }

  async createForUser(userId, data) {
    return this.model.create({ ...data, userId });
  }
}

module.exports = new RelativeRepository();