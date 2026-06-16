const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Periodic device status snapshot: battery, heart rate, and online flag.
 */
const DeviceStatus = sequelize.define(
  'DeviceStatus',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    deviceId: {
      type: DataTypes.UUID,
      allowNull: false,
      field: 'device_id',
      references: {
        model: 'devices',
        key: 'id',
      },
    },
    batteryPercent: {
      type: DataTypes.TINYINT.UNSIGNED,
      allowNull: false,
      field: 'battery_percent',
      validate: {
        min: 0,
        max: 100,
      },
    },
    heartRateBpm: {
      type: DataTypes.SMALLINT.UNSIGNED,
      allowNull: true,
      field: 'heart_rate_bpm',
    },
    isOnline: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
      field: 'is_online',
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: false,
    },
  },
  {
    tableName: 'device_statuses',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [
      { fields: ['device_id'] },
      { fields: ['timestamp'] },
    ],
  },
);

module.exports = DeviceStatus;
