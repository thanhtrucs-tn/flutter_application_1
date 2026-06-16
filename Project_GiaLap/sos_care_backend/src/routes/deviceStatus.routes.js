const express = require('express');
const deviceStatusController = require('../controllers/deviceStatus.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/deviceAuth.middleware');
const deviceStatusSchema = require('../validations/deviceStatus.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(deviceStatusSchema), deviceStatusController.create);

module.exports = router;
