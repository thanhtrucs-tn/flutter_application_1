const response = require('../utils/response.util');

class HealthController {
  check(req, res) {
    return response.success(res, { status: 'ok', uptime: process.uptime() }, 'Hệ thống hoạt động bình thường');
  }
}

module.exports = new HealthController();
