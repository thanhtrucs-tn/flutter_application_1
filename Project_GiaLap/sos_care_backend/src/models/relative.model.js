const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Elderly person profile owned by a caregiver account.
 *
 * Vitals and status are never stored here — they are derived at read time from
 * the latest device location/status rows plus active alerts. `deviceElderlyId`
 * is the business key a physical device emits (e.g. 'ELDERLY-001') and is the
 * pairing link between a relative and the device telemetry stream.
 */
const Relative = sequelize.define(
  'Relative',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'user_id',
      references: {
        model: 'users',
        key: 'id',
      },
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    avatar: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    age: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    address: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    wearableDevice: {
      type: DataTypes.STRING(100),
      allowNull: true,
      field: 'wearable_device',
    },
    deviceElderlyId: {
      type: DataTypes.STRING(100),
      allowNull: true,
      unique: true,
      field: 'device_elderly_id',
    },
    safeZoneRadius: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: true,
      defaultValue: 500,
      field: 'safe_zone_radius',
    },
    safeZoneLat: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
      field: 'safe_zone_lat',
    },
    safeZoneLng: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
      field: 'safe_zone_lng',
    },
  },
  {
    tableName: 'relatives',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [{ fields: ['user_id'] }],
  },
);

module.exports = Relative;