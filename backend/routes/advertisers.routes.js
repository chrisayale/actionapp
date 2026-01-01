const express = require('express');
const router = express.Router();
const advertisersController = require('../controllers/advertisers.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(verifyToken);

// POST /api/advertisers - Create a new establishment
router.post('/', advertisersController.createEstablishment);

// GET /api/advertisers - Get all establishments for the authenticated user
router.get('/', advertisersController.getEstablishments);

// GET /api/advertisers/:id - Get a single establishment
router.get('/:id', advertisersController.getEstablishmentById);

// PUT /api/advertisers/:id - Update an establishment
router.put('/:id', advertisersController.updateEstablishment);

// DELETE /api/advertisers/:id - Delete an establishment
router.delete('/:id', advertisersController.deleteEstablishment);

module.exports = router;



