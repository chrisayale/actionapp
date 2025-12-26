const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// POST /api/auth/login
router.post('/login', authController.login);

// POST /api/auth/register
router.post('/register', authController.register);

// POST /api/auth/logout
router.post('/logout', authController.logout);

// GET /api/auth/verify
router.get('/verify', authController.verifyToken);

module.exports = router;

