const Joi = require('joi');

const sosSchema = Joi.object({
  deviceId: Joi.string().required(),
  elderlyId: Joi.string().optional(),
  timestamp: Joi.alternatives()
    .try(Joi.date().iso(), Joi.string().isoDate())
    .required(),
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
  type: Joi.string().valid('SOS').default('SOS'),
});

module.exports = sosSchema;
