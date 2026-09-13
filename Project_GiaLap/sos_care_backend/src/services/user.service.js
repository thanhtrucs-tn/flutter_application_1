const { User, Relative, Device } = require('../models');
const AppError = require('../utils/app_error.util');

/**
 * Lấy thông tin tài khoản (user). Trả về public profile — không bao giờ
 * expose passwordHash. Kèm số liệu (relatives/devices) để client hiển thị.
 */
class UserService {
  async _public(user) {
    const [relatives, devices] = await Promise.all([
      Relative.count({ where: { userId: user.id } }),
      Device.count({ where: { userId: user.id } }),
    ]);
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      stats: { relatives, devices },
    };
  }

  async getMe(userId) {
    const user = await User.findByPk(userId);
    if (!user) throw new AppError('Không tìm thấy người dùng', 404);
    return this._public(user);
  }

  async getById(id) {
    const user = await User.findByPk(id);
    if (!user) throw new AppError('Không tìm thấy người dùng', 404);
    return this._public(user);
  }
}

module.exports = new UserService();