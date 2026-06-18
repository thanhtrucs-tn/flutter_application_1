const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Caregiver-facing alert. Created by the backend when a device SOS/event
 * arrives or when a geofence breach is computed. Separate from the raw device
 * ingest tables (sos_alerts/events) which hold device telemetry.
 *
 * `userId` is denormalized from the matched relative for fast user-scoped
 * queries. `sourceType`/`sourceId` trace the originating telemetry row, if any.
 */
const Alert = sequelize.define(
  'Alert',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    relativeId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'relative_id',
      references: {
        model: 'relatives',
        key: 'id',
      },
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
    type: {
      type: DataTypes.ENUM('sos', 'fall', 'geofence', 'vital', 'manual'),
      allowNull: false,
    },
    urgency: {
      type: DataTypes.ENUM('critical', 'warning'),
      allowNull: false,
    },
    message: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    locationName: {
      type: DataTypes.STRING(255),
      allowNull: true,
      field: 'location_name',
    },
    latitude: {
      type: DataTypes.DECIMAL(10, 8),
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DECIMAL(11, 8),
      allowNull: true,
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    acknowledged: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    read: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    sourceType: {
      type: DataTypes.STRING(20),
      allowNull: true,
      field: 'source_type',
    },
    sourceId: {
      type: DataTypes.STRING(64),
      allowNull: true,
      field: 'source_id',
    },
  },
  {
    tableName: 'alerts',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [
      { fields: ['relative_id'] },
      { fields: ['user_id'] },
      { fields: ['timestamp'] },
      { fields: ['user_id', 'acknowledged'] },
      { fields: ['user_id', 'read'] },
    ],
  },
);

module.exports = Alert;