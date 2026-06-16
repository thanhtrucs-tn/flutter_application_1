const sosService = require('../services/sos.service');
const response = require('../utils/response.util');

class SosController {
  async create(req, res, next) {
    try {
      const alert = await sosService.create(req.body);
      return response.success(
        res,
        { id: alert.id, type: alert.type, timestamp: alert.timestamp },
        'Đã nhận cảnh báo SOS',
        201,
      );
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new SosController();
