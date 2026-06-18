const Joi = require('joi');
const { createContactSchema } = require('./emergencyContact.schema');

/**
 * Relative profile create/update payloads. `contacts` is an optional array of
 * structured emergency contacts; when present on create/update the service
 * bulk-replaces the relative's contacts.
 */
const createRelativeSchema = Joi.object({
  name: Joi.string().max(255).required(),
  avatar: Joi.string().max(255).allow('', null).optional(),
  age: Joi.number().integer().min(0).max(150).allow(null).optional(),
  address: Joi.string().max(255).allow('', null).optional(),
  wearableDevice: Joi.string().max(100).allow('', null).optional(),
  deviceElderlyId: Joi.string().max(100).allow('', null).optional(),
  safeZoneRadius: Joi.number().min(0).max(100000).allow(null).optional(),
  safeZoneLat: Joi.number().min(-90).max(90).allow(null).optional(),
  safeZoneLng: Joi.number().min(-180).max(180).allow(null).optional(),
  contacts: Joi.array().items(createContactSchema).optional(),
});

const updateRelativeSchema = createRelativeSchema.keys({
  name: Joi.string().max(255).optional(),
});

module.exports = { createRelativeSchema, updateRelativeSchema };