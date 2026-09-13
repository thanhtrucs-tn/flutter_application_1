const express = require('express');
const locationController = require('../controllers/location.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/device_auth.middleware');
const locationSchema = require('../validations/location.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(locationSchema), locationController.create);

module.exports = router;
