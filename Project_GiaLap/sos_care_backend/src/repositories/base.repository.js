/**
 * Generic repository that wraps Sequelize model CRUD operations.
 *
 * Specific repositories extend this class to inherit common queries
 * while still being able to add model-specific methods.
 */
class BaseRepository {
  constructor(model) {
    this.model = model;
  }

  async create(data) {
    return this.model.create(data);
  }

  async findById(id, options = {}) {
    return this.model.findByPk(id, options);
  }

  async findOne(options = {}) {
    return this.model.findOne(options);
  }

  async findAll(options = {}) {
    return this.model.findAll(options);
  }

  async update(id, data) {
    const record = await this.findById(id);
    if (!record) return null;
    return record.update(data);
  }

  async delete(id) {
    const record = await this.findById(id);
    if (!record) return false;
    await record.destroy();
    return true;
  }

  async count(options = {}) {
    return this.model.count(options);
  }
}

module.exports = BaseRepository;
