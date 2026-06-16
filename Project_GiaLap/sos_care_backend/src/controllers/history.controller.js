const historyService = require('../services/history.service');
const response = require('../utils/response.util');

class HistoryController {
  async list(req, res, next) {
    try {
      const result = await historyService.list(req.query);
      return response.success(res, result.data, 'Lịch sử hoạt động', 200, result.meta);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new HistoryController();
