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
      // Chỉ cho đọc hồ sơ của chính mình — trả 404 để không lộ sự tồn tại
      // của tài khoản khác.
      if (String(req.params.id) !== String(req.user.id)) {
        return response.error(res, 'Không tìm thấy người dùng', 404);
      }
      const data = await userService.getById(req.user.id);
      return response.success(res, data, 'Thông tin người dùng');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new UserController();