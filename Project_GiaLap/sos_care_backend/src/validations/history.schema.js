const Joi = require('joi');

const historyQuerySchema = Joi.object({
  deviceId: Joi.string().optional(),
  type: Joi.string().valid('sos', 'event', 'location').optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

module.exports = historyQuerySchema;
