const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../config/env.config');
const { User } = require('../models');
const AppError = require('../utils/appError.util');

/**
 * Service for caregiver/admin authentication and profile management.
 * Register and login both return the public profile plus a JWT so the Flutter
 * client can enter the app immediately after either flow.
 */
class AuthService {
  _profile(user) {
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
    };
  }

  async register(payload) {
    const { email, password, role, name, phone } = payload;

    const existing = await User.findOne({ where: { email } });
    if (existing) {
      throw new AppError('Email đã được sử dụng', 409);
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({
      email,
      passwordHash,
      role,
      name: name || null,
      phone: phone || null,
    });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      env.jwt.secret,
      { expiresIn: env.jwt.expiresIn },
    );

    return { user: this._profile(user), token };
  }

  async login(payload) {
    const { email, password } = payload;

    const user = await User.findOne({ where: { email } });
    if (!user) {
      throw new AppError('Email hoặc mật khẩu không đúng', 401);
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      throw new AppError('Email hoặc mật khẩu không đúng', 401);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      env.jwt.secret,
      { expiresIn: env.jwt.expiresIn },
    );

    return { user: this._profile(user), token };
  }

  async getProfile(id) {
    const user = await User.findByPk(id);
    if (!user) throw new AppError('Không tìm thấy người dùng', 404);
    return this._profile(user);
  }

  async updateProfile(id, payload) {
    const user = await User.findByPk(id);
    if (!user) throw new AppError('Không tìm thấy người dùng', 404);
    const { name, phone, avatarUrl } = payload;
    await user.update({
      ...(name !== undefined ? { name: name || null } : {}),
      ...(phone !== undefined ? { phone: phone || null } : {}),
      ...(avatarUrl !== undefined ? { avatarUrl: avatarUrl || null } : {}),
    });
    return this._profile(user);
  }
}

module.exports = new AuthService();