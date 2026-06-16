const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * GPS location update received from a device.
 */
const Location = sequelize.define(
  'Location',
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
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: false,
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: false,
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: false,
    },
  },
  {
    tableName: 'locations',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [
      { fields: ['device_id'] },
      { fields: ['timestamp'] },
    ],
  },
);

module.exports = Location;
