const BaseRepository = require('./base.repository');
const { Alert } = require('../models');

/**
 * Repository for the caregiver-facing Alert model. Reads are scoped by the
 * owning caregiver so a user only ever sees their own alerts.
 */
class AlertRepository extends BaseRepository {
  constructor() {
    super(Alert);
  }

  async findByUserId(userId, { limit = 100, offset = 0 } = {}) {
    return this.model.findAll({
      where: { userId },
      order: [['timestamp', 'DESC']],
      limit,
      offset,
    });
  }

  async findByIdForUser(id, userId) {
    return this.model.findOne({ where: { id, userId } });
  }

  async findActiveByRelativeId(relativeId) {
    return this.model.findOne({
      where: { relativeId, acknowledged: false },
      order: [['timestamp', 'DESC']],
    });
  }

  async countUnreadByUser(userId) {
    return this.model.count({ where: { userId, read: false } });
  }

  async markAllReadByUser(userId) {
    const [updatedCount] = await this.model.update(
      { read: true },
      { where: { userId, read: false } },
    );
    return updatedCount;
  }
}

module.exports = new AlertRepository();