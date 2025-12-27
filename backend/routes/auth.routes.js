const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// OTP Authentication endpoints (Mobile)
// POST /api/auth/verify-token - Verify Firebase ID token
router.post('/verify-token', authController.verifyToken);

// POST /api/auth/create-profile - Create/update user profile after OTP verification
router.post('/create-profile', authController.createProfile);

// GET /api/auth/profile - Get user profile
router.get('/profile', authController.getProfile);

// PUT /api/auth/profile - Update user profile
router.put('/profile', authController.updateProfile);

// GET /api/auth/check-phone - Check if phone number exists
router.get('/check-phone', authController.checkPhone);

// Email/Password Authentication endpoints (Admin/Web)
// POST /api/auth/login
router.post('/login', authController.login);

// POST /api/auth/register
router.post('/register', authController.register);

// POST /api/auth/logout
router.post('/logout', authController.logout);

// Legacy endpoint (kept for backward compatibility)
// GET /api/auth/verify
router.get('/verify', authController.verifyToken);

module.exports = router;


