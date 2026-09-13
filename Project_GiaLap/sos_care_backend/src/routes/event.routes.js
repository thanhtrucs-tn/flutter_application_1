const express = require('express');
const eventController = require('../controllers/event.controller');
const validate = require('../middleware/validate.middleware');
const deviceAuth = require('../middleware/device_auth.middleware');
const eventSchema = require('../validations/event.schema');

const router = express.Router();

router.post('/', deviceAuth, validate(eventSchema), eventController.create);

module.exports = router;
