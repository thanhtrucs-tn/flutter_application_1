const Joi = require('joi');

const eventSchema = Joi.object({
  deviceId: Joi.string().required(),
  elderlyId: Joi.string().optional(),
  timestamp: Joi.alternatives()
    .try(Joi.date().iso(), Joi.string().isoDate())
    .required(),
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  type: Joi.string().valid('FALL_DETECTED', 'HEART_RATE_ALERT').required(),
});

module.exports = eventSchema;
