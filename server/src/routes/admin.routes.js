const express = require('express');
const router = express.Router();
const AdminController = require('../controllers/admin.controller');
const { protectRoute, isAdmin } = require('../middlewares/auth.middleware');

// Admin authentication routes
router.post('/login', AdminController.adminLogin);

// Admin dashboard routes (protected)
router.get('/dashboard/stats', protectRoute, AdminController.getDashboardStats);

// Provider management routes (protected)
router.get('/providers', protectRoute, AdminController.getAllProviders);
router.get('/providers/:providerId', protectRoute, AdminController.getProviderById);
router.post('/providers/create', protectRoute, isAdmin, AdminController.createProvider);
router.put('/providers/:providerId/status', protectRoute, AdminController.updateProviderStatus);
router.put('/providers/bulk-update', protectRoute, AdminController.bulkUpdateProviders);

// Booking management routes (protected)
router.get('/bookings', protectRoute, AdminController.getAllBookings);
router.get('/bookings/analytics', protectRoute, AdminController.getBookingAnalytics);
router.get('/bookings/activity-feed', protectRoute, AdminController.getBookingActivityFeed);
router.get('/bookings/:bookingId', protectRoute, AdminController.getBookingDetails);

module.exports = router; 