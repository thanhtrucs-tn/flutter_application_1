const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Caregiver or administrator account that can view device history
 * and receive realtime alerts.
 */
const User = sequelize.define(
  'User',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    passwordHash: {
      type: DataTypes.STRING(255),
      allowNull: false,
      field: 'password_hash',
    },
    role: {
      type: DataTypes.ENUM('admin', 'caregiver'),
      allowNull: false,
      defaultValue: 'caregiver',
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },
    avatarUrl: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: 'avatar_url',
    },
  },
  {
    tableName: 'users',
    timestamps: true,
    paranoid: true,
    underscored: true,
  },
);

module.exports = User;
