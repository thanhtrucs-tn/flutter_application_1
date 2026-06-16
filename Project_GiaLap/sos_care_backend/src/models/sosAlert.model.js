const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Emergency SOS alert received from a device.
 */
const SosAlert = sequelize.define(
  'SosAlert',
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
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'SOS',
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
    status: {
      type: DataTypes.ENUM('pending', 'resolved', 'false_alarm'),
      allowNull: false,
      defaultValue: 'pending',
    },
    payloadJson: {
      type: DataTypes.JSON,
      allowNull: true,
      field: 'payload_json',
    },
  },
  {
    tableName: 'sos_alerts',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [
      { fields: ['device_id'] },
      { fields: ['timestamp'] },
    ],
  },
);

module.exports = SosAlert;
