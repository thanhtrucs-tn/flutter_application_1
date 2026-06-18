const Joi = require('joi');

const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  role: Joi.string().valid('admin', 'caregiver').default('caregiver'),
  name: Joi.string().max(100).allow('', null).optional(),
  phone: Joi.string().max(20).allow('', null).optional(),
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

const updateProfileSchema = Joi.object({
  name: Joi.string().max(100).allow('', null).optional(),
  phone: Joi.string().max(20).allow('', null).optional(),
  avatarUrl: Joi.string().max(255).allow('', null).optional(),
});

module.exports = {
  registerSchema,
  loginSchema,
  updateProfileSchema,
};