const Joi = require('joi');

const deviceStatusSchema = Joi.object({
  deviceId: Joi.string().required(),
  elderlyId: Joi.string().optional(),
  timestamp: Joi.alternatives()
    .try(Joi.date().iso(), Joi.string().isoDate())
    .required(),
  batteryPercent: Joi.number().integer().min(0).max(100).required(),
  heartRateBpm: Joi.number().integer().min(30).max(220).optional(),
  isOnline: Joi.boolean().optional(),
});

module.exports = deviceStatusSchema;
