const deviceStatusService = require('../services/deviceStatus.service');
const response = require('../utils/response.util');

class BatteryController {
  async create(req, res, next) {
    try {
      const status = await deviceStatusService.create({
        ...req.body,
        heartRateBpm: undefined,
        isOnline: undefined,
      });
      return response.success(
        res,
        { id: status.id, timestamp: status.timestamp },
        'Đã cập nhật mức pin',
        201,
      );
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new BatteryController();
