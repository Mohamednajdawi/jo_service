const Rating = require('../models/rating.model');
const Provider = require('../models/provider.model');
const Booking = require('../models/booking.model');
const mongoose = require('mongoose');

const RatingController = {
    // POST /api/ratings/provider - Create a new rating for a provider
    async createRating(req, res) {
        const { providerId, bookingId, rating, review } = req.body;
        const userId = req.auth.id;


        if (!providerId || !bookingId || !rating) {
            return res.status(400).json({ message: 'Provider ID, booking ID, and rating are required' });
        }

        try {
            // Validate provider exists
            const providerExists = await Provider.findById(providerId);
            if (!providerExists) {
                return res.status(404).json({ message: 'Provider not found' });
            }

            // Validate booking exists and belongs to this user
            const booking = await Booking.findById(bookingId);
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found' });
            }

            // Verify the booking belongs to this user
            if (booking.user.toString() !== userId) {
                return res.status(403).json({ message: 'You can only rate your own bookings' });
            }

            // Verify the booking is for this provider
            if (booking.provider.toString() !== providerId) {
                return res.status(400).json({ message: 'This booking is not for the specified provider' });
            }

            // Verify the booking is completed
            if (booking.status !== 'completed') {
                return res.status(400).json({ message: 'You can only rate completed bookings' });
            }

            // Check if user already rated this booking
            const existingRating = await Rating.findOne({ booking: bookingId, user: userId });
            if (existingRating) {
                return res.status(400).json({ message: 'You have already rated this booking' });
            }

            // Create the rating
            const newRating = new Rating({
                booking: bookingId,
                user: userId,
                provider: providerId,
                rating,
                review
            });

            const savedRating = await newRating.save();

            // Update provider's average rating
            const ratingStats = await Rating.calculateAverageRating(providerId);
            await Provider.findByIdAndUpdate(providerId, {
                averageRating: ratingStats.averageRating,
                totalRatings: ratingStats.totalRatings
            });

            res.status(201).json(savedRating);
        } catch (error) {
            console.error('Error creating rating:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation error', errors: error.errors });
            }
            if (error.code === 11000) {
                return res.status(400).json({ message: 'You have already rated this booking' });
            }
            res.status(500).json({ message: 'Failed to create rating', error: error.message });
        }
    },

    // GET /api/ratings/check/:bookingId - Check if user has rated a booking
    async checkRating(req, res) {
        const bookingId = req.params.bookingId;
        const userId = req.auth.id;


        try {
            const existingRating = await Rating.findOne({ booking: bookingId, user: userId });
            res.status(200).json({ hasRated: !!existingRating });
        } catch (error) {
            console.error('Error checking rating:', error);
            res.status(500).json({ message: 'Failed to check rating', error: error.message });
        }
    },

    // GET /api/ratings/provider/:providerId - Get ratings for a provider
    async getProviderRatings(req, res) {
        const providerId = req.params.providerId;
        const { page = 1, limit = 10 } = req.query;


        try {
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;

            const ratings = await Rating.find({ provider: providerId })
                .populate('user', 'fullName profilePictureUrl')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum);

            const totalRatings = await Rating.countDocuments({ provider: providerId });

            // Get the provider's average rating
            const provider = await Provider.findById(providerId, 'averageRating totalRatings');

            res.status(200).json({
                ratings,
                currentPage: pageNum,
                totalPages: Math.ceil(totalRatings / limitNum),
                totalRatings,
                averageRating: provider ? provider.averageRating : 0
            });
        } catch (error) {
            console.error('Error getting provider ratings:', error);
            res.status(500).json({ message: 'Failed to get provider ratings', error: error.message });
        }
    },

    // GET /api/ratings/user - Get ratings submitted by the logged-in user
    async getUserRatings(req, res) {
        const userId = req.auth.id;
        const { page = 1, limit = 10 } = req.query;


        try {
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;

            const ratings = await Rating.find({ user: userId })
                .populate('provider', 'fullName serviceType profilePictureUrl')
                .populate('booking')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limitNum);

            const totalRatings = await Rating.countDocuments({ user: userId });

            res.status(200).json({
                ratings,
                currentPage: pageNum,
                totalPages: Math.ceil(totalRatings / limitNum),
                totalRatings
            });
        } catch (error) {
            console.error('Error getting user ratings:', error);
            res.status(500).json({ message: 'Failed to get user ratings', error: error.message });
        }
    }
};

module.exports = RatingController; 