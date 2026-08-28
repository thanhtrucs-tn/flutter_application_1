const express = require('express');
const optionalAuth = require('../middleware/optionalAuth.middleware');
const userController = require('../controllers/user.controller');

const router = express.Router();

// Các route này công khai (không bắt buộc token). Nếu có token hợp lệ,
// `req.user` được set để /me trả đúng tài khoản của người gọi.
router.use(optionalAuth);

router.get('/me', userController.getMe);
router.get('/profile', userController.getMe); // alias: /api/user/profile, /api/users/profile
router.get('/:id', userController.getById);
router.get('/', userController.list);

module.exports = router;