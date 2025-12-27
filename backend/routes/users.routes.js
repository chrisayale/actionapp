const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

// GET /api/users
router.get('/', authenticateToken, usersController.getAllUsers);

// GET /api/users/:id
router.get('/:id', authenticateToken, usersController.getUserById);

// PUT /api/users/:id
router.put('/:id', authenticateToken, usersController.updateUser);

// DELETE /api/users/:id
router.delete('/:id', authenticateToken, usersController.deleteUser);

module.exports = router;




