const express = require('express');
const sosController = require('../controllers/sos.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/deviceAuth.middleware');
const sosSchema = require('../validations/sos.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(sosSchema), sosController.create);

module.exports = router;
