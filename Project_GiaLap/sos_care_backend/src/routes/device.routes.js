const express = require('express');
const deviceController = require('../controllers/device.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/:id', authMiddleware, deviceController.getById);

module.exports = router;
