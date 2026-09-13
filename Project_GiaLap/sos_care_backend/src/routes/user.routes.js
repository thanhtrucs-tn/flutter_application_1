const express = require('express');
const authMiddleware = require('../middleware/auth.middleware');
const userController = require('../controllers/user.controller');

const router = express.Router();

// Mọi route user yêu cầu đăng nhập — tránh lộ thông tin tài khoản cho người lạ.
router.use(authMiddleware);

router.get('/me', userController.getMe);
router.get('/profile', userController.getMe); // alias: /api/user/profile, /api/users/profile
router.get('/:id', userController.getById);

module.exports = router;