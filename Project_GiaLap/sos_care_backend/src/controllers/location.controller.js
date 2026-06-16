const locationService = require('../services/location.service');
const response = require('../utils/response.util');

class LocationController {
  async create(req, res, next) {
    try {
      const location = await locationService.create(req.body);
      return response.success(
        res,
        { id: location.id, timestamp: location.timestamp },
        'Đã nhận vị trí thiết bị',
        201,
      );
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new LocationController();
