const express = require('express');
const BookingController = require('../controllers/booking.controller');
const { protectRoute, isUser, isProvider } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');

const router = express.Router();

// POST /api/bookings - User creates a booking request (with optional photo uploads)
router.post('/', protectRoute, isUser, upload.array('photos', 10), BookingController.createBooking);

// GET /api/bookings/user - Get bookings for the logged-in user
router.get('/user', protectRoute, isUser, BookingController.getBookingsForUser);

// GET /api/bookings/provider - Get bookings for the logged-in provider
router.get('/provider', protectRoute, isProvider, BookingController.getBookingsForProvider);

// TEST ROUTE - temporary for debugging
router.get('/test-all', protectRoute, BookingController.getAllBookingsForTest);

// SPECIAL DEBUG ROUTE - Get bookings for a specific user ID
router.get('/by-user/:userId', protectRoute, BookingController.getBookingsByUserId);

// SPECIAL DEBUG ROUTE - Get bookings for a specific provider ID
router.get('/by-provider/:providerId', protectRoute, BookingController.getBookingsByProviderId);

// SPECIAL DEBUG ROUTE - Reassign a booking to a different provider
router.patch('/:id/reassign', protectRoute, BookingController.reassignBooking);

// GET /api/bookings/:id - Get a specific booking (user or provider)
// protectRoute ensures logged in, controller logic verifies ownership
router.get('/:id', protectRoute, BookingController.getBookingById);

// PATCH /api/bookings/:id/status - Update booking status (user or provider)
// protectRoute ensures logged in, controller logic verifies ownership and transition rules
router.patch('/:id/status', protectRoute, BookingController.updateBookingStatus);

module.exports = router; 