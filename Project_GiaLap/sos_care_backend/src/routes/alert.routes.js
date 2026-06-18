const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const alertController = require('../controllers/alert.controller');
const { manualAlertSchema, paginationSchema } = require('../validations/alert.schema');

const router = express.Router();

// All alert routes require a valid caregiver JWT.
router.use(authMiddleware);

router.get('/', validate(paginationSchema, 'query'), alertController.list);
router.post('/', validate(manualAlertSchema), alertController.createManual);
router.patch('/:id/acknowledge', alertController.acknowledge);
router.patch('/:id/read', alertController.markRead);
router.post('/mark-all-read', alertController.markAllRead);

module.exports = router;