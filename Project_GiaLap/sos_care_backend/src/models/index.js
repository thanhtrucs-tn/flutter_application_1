const sequelize = require('../config/database');
const User = require('./user.model');
const Device = require('./device.model');
const SosAlert = require('./sosAlert.model');
const Event = require('./event.model');
const Location = require('./location.model');
const DeviceStatus = require('./deviceStatus.model');

/**
 * Define associations between models.
 *
 * A user can manage many devices. Each device can have many alerts,
 * events, locations, and status records.
 */
Device.belongsTo(User, { foreignKey: 'userId', as: 'caregiver' });
User.hasMany(Device, { foreignKey: 'userId', as: 'devices' });

SosAlert.belongsTo(Device, { foreignKey: 'deviceId', as: 'device' });
Device.hasMany(SosAlert, { foreignKey: 'deviceId', as: 'sosAlerts' });

Event.belongsTo(Device, { foreignKey: 'deviceId', as: 'device' });
Device.hasMany(Event, { foreignKey: 'deviceId', as: 'events' });

Location.belongsTo(Device, { foreignKey: 'deviceId', as: 'device' });
Device.hasMany(Location, { foreignKey: 'deviceId', as: 'locations' });

DeviceStatus.belongsTo(Device, { foreignKey: 'deviceId', as: 'device' });
Device.hasMany(DeviceStatus, { foreignKey: 'deviceId', as: 'statuses' });

const db = {
  sequelize,
  User,
  Device,
  SosAlert,
  Event,
  Location,
  DeviceStatus,
};

module.exports = db;
