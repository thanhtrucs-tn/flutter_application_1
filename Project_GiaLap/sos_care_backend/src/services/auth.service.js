const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../config/env.config');
const { User } = require('../models');
const AppError = require('../utils/appError.util');

/**
 * Service for caregiver/admin authentication.
 */
class AuthService {
  async register(payload) {
    const { email, password, role } = payload;

    const existing = await User.findOne({ where: { email } });
    if (existing) {
      throw new AppError('Email đã được sử dụng', 409);
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({ email, passwordHash, role });

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
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

    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      token,
    };
  }
}

module.exports = new AuthService();
