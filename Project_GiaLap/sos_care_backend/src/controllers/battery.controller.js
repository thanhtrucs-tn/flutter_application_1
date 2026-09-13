const deviceStatusService = require('../services/device_status.service');
const response = require('../utils/response.util');

class BatteryController {
  async create(req, res, next) {
    try {
      // Endpoint pin chỉ nhận thông số pin; không ghi đè nhịp tim/trạng thái
      // online do endpoint /api/device/status quản lý.
      const { heartRateBpm, isOnline, ...batteryPayload } = req.body;
      const status = await deviceStatusService.create(batteryPayload);
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
