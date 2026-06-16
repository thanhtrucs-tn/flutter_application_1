const express = require('express');
const batteryController = require('../controllers/battery.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/deviceAuth.middleware');
const batterySchema = require('../validations/battery.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(batterySchema), batteryController.create);

module.exports = router;
