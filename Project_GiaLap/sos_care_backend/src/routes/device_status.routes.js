const express = require('express');
const deviceStatusController = require('../controllers/device_status.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/device_auth.middleware');
const deviceStatusSchema = require('../validations/device_status.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(deviceStatusSchema), deviceStatusController.create);

module.exports = router;
