const express = require('express');
const historyController = require('../controllers/history.controller');
const validate = require('../middleware/validate.middleware');
const historySchema = require('../validations/history.schema');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

router.get(
  '/',
  authMiddleware,
  validate(historySchema, 'query'),
  historyController.list,
);

module.exports = router;
