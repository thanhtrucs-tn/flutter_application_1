const deviceStatusService = require('../services/deviceStatus.service');
const response = require('../utils/response.util');

class DeviceStatusController {
  async create(req, res, next) {
    try {
      const status = await deviceStatusService.create(req.body);
      return response.success(
        res,
        { id: status.id, timestamp: status.timestamp },
        'Đã cập nhật trạng thái thiết bị',
        201,
      );
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DeviceStatusController();
