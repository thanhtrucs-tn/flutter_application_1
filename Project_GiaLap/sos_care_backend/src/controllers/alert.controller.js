const alertService = require('../services/alert.service');
const response = require('../utils/response.util');

class AlertController {
  async list(req, res, next) {
    try {
      const data = await alertService.listByUser(req.user.id, req.query);
      const unread = await alertService.countUnreadByUser(req.user.id);
      return response.success(res, data, 'Danh sách cảnh báo', 200, { unread });
    } catch (err) {
      next(err);
    }
  }

  async acknowledge(req, res, next) {
    try {
      const data = await alertService.acknowledge(req.params.id, req.user.id);
      return response.success(res, data, 'Đã xác nhận cảnh báo');
    } catch (err) {
      next(err);
    }
  }

  async markRead(req, res, next) {
    try {
      const data = await alertService.markRead(req.params.id, req.user.id);
      return response.success(res, data);
    } catch (err) {
      next(err);
    }
  }

  async markAllRead(req, res, next) {
    try {
      const count = await alertService.markAllRead(req.user.id);
      return response.success(res, { markedRead: count }, 'Đã đánh dấu tất cả là đã đọc');
    } catch (err) {
      next(err);
    }
  }

  async createManual(req, res, next) {
    try {
      const data = await alertService.createManual(req.user.id, req.body);
      return response.success(res, data, 'Đã tạo cảnh báo', 201);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AlertController();