const eventService = require('../services/event.service');
const response = require('../utils/response.util');

class EventController {
  async create(req, res, next) {
    try {
      const event = await eventService.create(req.body);
      return response.success(
        res,
        { id: event.id, type: event.type, timestamp: event.timestamp },
        'Đã nhận sự kiện thiết bị',
        201,
      );
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new EventController();
