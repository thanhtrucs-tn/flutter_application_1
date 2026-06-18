const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const relativeController = require('../controllers/relative.controller');
const { createRelativeSchema, updateRelativeSchema } = require('../validations/relative.schema');
const { createContactSchema } = require('../validations/emergencyContact.schema');

const router = express.Router();

// All relative routes require a valid caregiver JWT.
router.use(authMiddleware);

router.get('/', relativeController.list);
router.post('/', validate(createRelativeSchema), relativeController.create);
router.get('/:id', relativeController.getById);
router.put('/:id', validate(updateRelativeSchema), relativeController.update);
router.delete('/:id', relativeController.remove);

router.get('/:id/contacts', relativeController.listContacts);
router.post('/:id/contacts', validate(createContactSchema), relativeController.addContact);
router.delete('/:id/contacts/:contactId', relativeController.removeContact);

module.exports = router;