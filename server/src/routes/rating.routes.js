const express = require('express');
const RatingController = require('../controllers/rating.controller');
const { protectRoute, isUser } = require('../middlewares/auth.middleware');

const router = express.Router();

// POST /api/ratings/provider - Create a new rating for a provider (user only)
router.post('/provider', protectRoute, isUser, RatingController.createRating);

// GET /api/ratings/check/:bookingId - Check if user has already rated a booking
router.get('/check/:bookingId', protectRoute, isUser, RatingController.checkRating);

// GET /api/ratings/provider/:providerId - Get ratings for a provider
router.get('/provider/:providerId', protectRoute, RatingController.getProviderRatings);

// GET /api/ratings/user - Get ratings submitted by the logged-in user
router.get('/user', protectRoute, isUser, RatingController.getUserRatings);

module.exports = router; 