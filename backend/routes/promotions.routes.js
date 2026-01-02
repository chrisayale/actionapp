const express = require('express');
const router = express.Router();
const promotionsController = require('../controllers/promotions.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// Public routes (no authentication required)
// GET /api/promotions/public - Get all active public promotions (for home page)
router.get('/public', promotionsController.getPublicPromotions);

// All other routes require authentication
router.use(verifyToken);

// POST /api/promotions/:id/interested - Toggle interested count (like button - requires auth)
router.post('/:id/interested', promotionsController.toggleInterested);

// POST /api/promotions - Create a new promotion
router.post('/', promotionsController.createPromotion);

// GET /api/promotions?establishmentId=xxx - Get all promotions for an establishment
router.get('/', promotionsController.getPromotions);

// GET /api/promotions/:id - Get a single promotion
router.get('/:id', promotionsController.getPromotionById);

// PUT /api/promotions/:id - Update a promotion
router.put('/:id', promotionsController.updatePromotion);

// DELETE /api/promotions/:id - Delete a promotion
router.delete('/:id', promotionsController.deletePromotion);

// PATCH /api/promotions/:id/toggle-active - Toggle promotion active status
router.patch('/:id/toggle-active', promotionsController.toggleActive);

// PATCH /api/promotions/:id/continue - Continue promotion (make it unlimited)
router.patch('/:id/continue', promotionsController.continuePromotion);

module.exports = router;



