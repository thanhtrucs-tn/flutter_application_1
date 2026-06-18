const express = require('express');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const { registerSchema, loginSchema, updateProfileSchema } = require('../validations/auth.schema');

const router = express.Router();

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);

// Profile endpoints require authentication.
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, validate(updateProfileSchema), authController.updateProfile);

module.exports = router;