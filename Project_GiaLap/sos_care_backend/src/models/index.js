const sequelize = require('../config/database');
const User = require('./user.model');
const Device = require('./device.model');
const SosAlert = require('./sosAlert.model');
const Event = require('./event.model');
const Location = require('./location.model');
const DeviceStatus = require('./deviceStatus.model');
const Relative = require('./relative.model');
const EmergencyContact = require('./emergencyContact.model');
const Alert = require('./alert.model');

/**
 * Define associations between models.
 *
 * A caregiver (User) manages many relatives (Relative) and devices. Each
 * relative has emergency contacts and caregiver-facing alerts. Each device
 * owns device telemetry: sos_alerts, events, locations, device_statuses.
 *
 * Note: onDelete behavior in associations is only applied by sequelize.sync,
 * which is disabled (DB_SYNC=false). Actual cascade rules live in the
 * migration FK definitions.
 */
Device.belongsTo(User, { foreignKey: 'userId', as: 'caregiver' });
User.hasMany(Device, { foreignKey: 'userId', as: 'devices' });

Relative.belongsTo(User, { foreignKey: 'userId', as: 'caregiver' });
User.hasMany(Relative, { foreignKey: 'userId', as: 'relatives', onDelete: 'CASCADE' });

EmergencyContact.belongsTo(Relative, { foreignKey: 'relativeId', as: 'relative' });
Relative.hasMany(EmergencyContact, { foreignKey: 'relativeId', as: 'contacts', onDelete: 'CASCADE' });

Alert.belongsTo(Relative, { foreignKey: 'relativeId', as: 'relative' });
Relative.hasMany(Alert, { foreignKey: 'relativeId', as: 'alerts', onDelete: 'CASCADE' });
Alert.belongsTo(User, { foreignKey: 'userId', as: 'user' });

Device.belongsTo(Relative, { foreignKey: 'relativeId', as: 'relative' });
Relative.hasOne(Device, { foreignKey: 'relativeId', as: 'device' });

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
  Relative,
  EmergencyContact,
  Alert,
};

module.exports = db;