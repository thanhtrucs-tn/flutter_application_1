const deviceService = require('../services/device.service');
const response = require('../utils/response.util');

class DeviceController {
  async getById(req, res, next) {
    try {
      const device = await deviceService.getById(req.params.id);
      return response.success(res, device, 'Thông tin thiết bị');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DeviceController();
