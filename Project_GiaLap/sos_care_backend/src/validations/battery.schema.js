const Joi = require('joi');

/**
 * Minimal battery update payload used by the legacy `/api/device/battery`
 * endpoint from the Flutter simulator.
 */
const batterySchema = Joi.object({
  deviceId: Joi.string().required(),
  elderlyId: Joi.string().optional(),
  timestamp: Joi.alternatives()
    .try(Joi.date().iso(), Joi.string().isoDate())
    .required(),
  batteryPercent: Joi.number().integer().min(0).max(100).required(),
});

module.exports = batterySchema;
