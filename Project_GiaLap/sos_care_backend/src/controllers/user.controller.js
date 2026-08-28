const userService = require('../services/user.service');
const response = require('../utils/response.util');

class UserController {
  async getMe(req, res, next) {
    try {
      if (!req.user || !req.user.id) {
        return response.error(
          res,
          'Chưa đăng nhập. Gửi kèm Authorization: Bearer <token> (lấy từ POST /api/auth/login) để xem tài khoản của bạn',
          401,
        );
      }
      const data = await userService.getMe(req.user.id);
      return response.success(res, data, 'Thông tin tài khoản');
    } catch (err) {
      next(err);
    }
  }

  async getById(req, res, next) {
    try {
      const data = await userService.getById(req.params.id);
      return response.success(res, data, 'Thông tin người dùng');
    } catch (err) {
      next(err);
    }
  }

  async list(req, res, next) {
    try {
      if (req.query.email) {
        const data = await userService.findByEmail(req.query.email);
        return response.success(res, data, 'Thông tin người dùng');
      }
      const data = await userService.list();
      return response.success(res, data, 'Danh sách người dùng');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new UserController();