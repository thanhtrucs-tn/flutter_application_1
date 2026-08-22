const relativeService = require('../services/relative.service');
const response = require('../utils/response.util');

class RelativeController {
  async list(req, res, next) {
    try {
      const data = await relativeService.listByUser(req.user.id);
      return response.success(res, data, 'Danh sách người thân');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await relativeService.getById(req.params.id, req.user.id);
      return response.success(res, data);
    } catch (err) {
      next(err);
    }
  }

  async create(req, res, next) {
    try {
      const data = await relativeService.create(req.user.id, req.body);
      return response.success(res, data, 'Đã thêm người thân', 201);
    } catch (err) {
      next(err);
    }
  }

  async update(req, res, next) {
    try {
      const data = await relativeService.update(req.params.id, req.user.id, req.body);
      return response.success(res, data, 'Đã cập nhật người thân');
    } catch (err) {
      next(err);
    }
  }

  async uploadAvatar(req, res, next) {
    try {
      const data = await relativeService.updateAvatarPhoto(req.params.id, req.user.id, req.file);
      return response.success(res, data, 'Đã cập nhật ảnh đại diện');
    } catch (err) {
      next(err);
    }
  }

  async remove(req, res, next) {
    try {
      await relativeService.remove(req.params.id, req.user.id);
      return response.success(res, null, 'Đã xóa người thân');
    } catch (err) {
      next(err);
    }
  }

  async listContacts(req, res, next) {
    try {
      const data = await relativeService.listContacts(req.params.id, req.user.id);
      return response.success(res, data);
    } catch (err) {
      next(err);
    }
  }

  async addContact(req, res, next) {
    try {
      const data = await relativeService.addContact(req.params.id, req.user.id, req.body);
      return response.success(res, data, 'Đã thêm liên hệ', 201);
    } catch (err) {
      next(err);
    }
  }

  async removeContact(req, res, next) {
    try {
      await relativeService.removeContact(req.params.id, req.params.contactId, req.user.id);
      return response.success(res, null, 'Đã xóa liên hệ');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new RelativeController();