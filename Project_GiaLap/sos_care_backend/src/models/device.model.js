const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Simulated SOS wearable device assigned to an elderly person.
 */
const Device = sequelize.define(
  'Device',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    elderlyId: {
      type: DataTypes.STRING(100),
      allowNull: false,
      field: 'elderly_id',
    },
    elderlyName: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: 'elderly_name',
    },
    serialNumber: {
      type: DataTypes.STRING(100),
      allowNull: true,
      unique: true,
      field: 'serial_number',
    },
    status: {
      type: DataTypes.ENUM('active', 'inactive', 'lost'),
      allowNull: false,
      defaultValue: 'active',
    },
    lastSeenAt: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'last_seen_at',
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'user_id',
      references: {
        model: 'users',
        key: 'id',
      },
    },
  },
  {
    tableName: 'devices',
    timestamps: true,
    paranoid: true,
    underscored: true,
  },
);

module.exports = Device;
