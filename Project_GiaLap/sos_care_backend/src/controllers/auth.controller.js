const authService = require('../services/auth.service');
const response = require('../utils/response.util');

class AuthController {
  async register(req, res, next) {
    try {
      const user = await authService.register(req.body);
      return response.success(res, user, 'Đăng ký thành công', 201);
    } catch (err) {
      next(err);
    }
  }

  async login(req, res, next) {
    try {
      const result = await authService.login(req.body);
      return response.success(res, result, 'Đăng nhập thành công');
    } catch (err) {
      next(err);
    }
  }

  async getProfile(req, res, next) {
    try {
      const profile = await authService.getProfile(req.user.id);
      return response.success(res, profile);
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const profile = await authService.updateProfile(req.user.id, req.body);
      return response.success(res, profile, 'Đã cập nhật hồ sơ');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
