const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/orders.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

// GET /api/orders
router.get('/', authenticateToken, ordersController.getAllOrders);

// GET /api/orders/:id
router.get('/:id', authenticateToken, ordersController.getOrderById);

// POST /api/orders
router.post('/', authenticateToken, ordersController.createOrder);

// PUT /api/orders/:id
router.put('/:id', authenticateToken, ordersController.updateOrder);

// DELETE /api/orders/:id
router.delete('/:id', authenticateToken, ordersController.deleteOrder);

module.exports = router;




