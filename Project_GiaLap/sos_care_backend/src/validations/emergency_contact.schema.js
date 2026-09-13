const Joi = require('joi');

/**
 * Validation for a single emergency contact (name + phone + relationship).
 */
const createContactSchema = Joi.object({
  name: Joi.string().max(100).required(),
  phone: Joi.string().max(20).required(),
  relationship: Joi.string().max(50).allow('', null).optional(),
});

module.exports = { createContactSchema };