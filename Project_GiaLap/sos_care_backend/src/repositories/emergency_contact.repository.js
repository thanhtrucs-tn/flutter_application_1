const BaseRepository = require('./base.repository');
const { EmergencyContact } = require('../models');

/**
 * Repository for the EmergencyContact model.
 */
class EmergencyContactRepository extends BaseRepository {
  constructor() {
    super(EmergencyContact);
  }

  async findByRelativeId(relativeId) {
    return this.model.findAll({
      where: { relativeId },
      order: [['created_at', 'ASC']],
    });
  }

  // Hard-replace all contacts for a relative (used on relative create/update).
  async bulkReplaceForRelative(relativeId, contacts) {
    await this.model.destroy({ where: { relativeId }, force: true });
    if (!contacts || contacts.length === 0) return [];
    return this.model.bulkCreate(
      contacts.map((c) => ({
        relativeId,
        name: c.name,
        phone: c.phone,
        relationship: c.relationship || null,
      })),
    );
  }

  async createForRelative(relativeId, data) {
    return this.model.create({ ...data, relativeId });
  }
}

module.exports = new EmergencyContactRepository();