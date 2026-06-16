const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Generic device event such as fall detection or heart rate alert.
 */
const Event = sequelize.define(
  'Event',
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
    type: {
      type: DataTypes.ENUM('FALL_DETECTED', 'HEART_RATE_ALERT'),
      allowNull: false,
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
    payloadJson: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'payload_json',
    },
  },
  {
    tableName: 'events',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [
      { fields: ['device_id'] },
      { fields: ['timestamp'] },
      { fields: ['type'] },
    ],
  },
);

module.exports = Event;
