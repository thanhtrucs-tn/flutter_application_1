const response = require('../utils/response.util');

/**
 * Generic Joi schema validator.
 *
 * Validates `req.body` against the provided schema by default. Set
 * `source` to `'query'` to validate query parameters.
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const data = source === 'query' ? req.query : req.body;
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      allowUnknown: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));
      return response.error(res, 'Dữ liệu không hợp lệ', 400, errors);
    }

    if (source === 'query') {
      req.query = value;
    } else {
      req.body = value;
    }

    next();
  };
};

module.exports = validate;
