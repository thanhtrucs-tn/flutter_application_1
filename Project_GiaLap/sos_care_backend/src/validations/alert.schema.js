const Joi = require('joi');

const manualAlertSchema = Joi.object({
  relativeId: Joi.number().integer().allow(null).optional(),
  type: Joi.string().valid('sos', 'fall', 'geofence', 'vital', 'manual').default('manual'),
  urgency: Joi.string().valid('critical', 'warning').default('warning'),
  message: Joi.string().max(500).required(),
  locationName: Joi.string().max(255).allow('', null).optional(),
  latitude: Joi.number().min(-90).max(90).allow(null).optional(),
  longitude: Joi.number().min(-180).max(180).allow(null).optional(),
  timestamp: Joi.string().isoDate().optional(),
});

const paginationSchema = Joi.object({
  limit: Joi.number().integer().min(1).max(500).default(100),
  offset: Joi.number().integer().min(0).default(0),
});

module.exports = { manualAlertSchema, paginationSchema };