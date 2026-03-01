const Booking = require('../models/booking.model');
const Provider = require('../models/provider.model');
const mongoose = require('mongoose');
const notificationService = require('../services/notification.service');

const BookingController = {
    // POST /api/bookings - Create a new booking (by User)
    async createBooking(req, res) {
        const { providerId, serviceDateTime, serviceLocationDetails, userNotes } = req.body;
        const userId = req.auth.id; // Assuming protectRoute middleware adds auth object with user ID
        const uploadedFiles = req.files || []; // Files uploaded via multer
        

        if (!providerId || !serviceDateTime) {
            return res.status(400).json({ message: 'Provider ID and service date/time are required.' });
        }

        try {
            // Check if provider exists and is verified
            const providerExists = await Provider.findOne({
                _id: providerId,
                verificationStatus: 'verified'
            });
            if (!providerExists) {
                return res.status(404).json({ message: 'Provider not found or not available for booking.' });
            }

            // Process uploaded photos
            const photoUrls = [];
            if (uploadedFiles && uploadedFiles.length > 0) {
                uploadedFiles.forEach(file => {
                    // Create relative URL path for the uploaded file
                    const photoUrl = `/uploads/${file.filename}`;
                    photoUrls.push(photoUrl);
                });
            }

            const newBooking = new Booking({
                user: userId,
                provider: providerId,
                serviceDateTime,
                serviceLocationDetails,
                userNotes,
                photos: photoUrls, // Add photo URLs to booking
                status: 'pending' // Initial status
            });

            const savedBooking = await newBooking.save();

            // Populate user and provider details before sending response
            const populatedBooking = await Booking.findById(savedBooking._id)
                .populate('user', 'fullName email profilePictureUrl') // Select specific user fields
                .populate('provider', 'fullName email serviceType profilePictureUrl'); // Select provider fields

            res.status(201).json(populatedBooking);

        } catch (error) {
            console.error('Error creating booking:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation Error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to create booking', error: error.message });
        }
    },

    // GET /api/bookings/user - Get bookings for the logged-in user
    async getBookingsForUser(req, res) {
        const userId = req.auth.id;
        const { status, page = 1, limit = 10 } = req.query; // Allow filtering by status
        

        try {
            // Verify the user ID is a valid MongoDB ObjectId
            if (!mongoose.Types.ObjectId.isValid(userId)) {
                return res.status(400).json({ message: 'Invalid user ID format' });
            }

            // Create an ObjectId from the userId string for proper MongoDB comparison
            const userObjectId = new mongoose.Types.ObjectId(userId);
            
            // Query with the ObjectId
            const query = { user: userObjectId };
            if (status) {
                query.status = status;
            }
            

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 }, // Sort by newest first
                populate: { 
                    path: 'provider', 
                    select: 'fullName email serviceType profilePictureUrl averageRating' 
                } // Populate provider details
            };
            
            // Log the query we're about to execute
            
            const bookings = await Booking.find(query)
                .populate('user') // Fully populate user to debug
                .populate(options.populate)
                .sort(options.sort)
                .skip((options.page - 1) * options.limit)
                .limit(options.limit);
            
            const totalBookings = await Booking.countDocuments(query);
            
            
            // Log the first booking to debug
            if (bookings.length > 0) {
            } else {
                // If no bookings found with direct query, try manual string comparison as fallback
                
                const allBookings = await Booking.find({})
                    .populate('user')
                    .populate(options.populate);
                    
                const matchingBookings = allBookings.filter(booking => 
                    booking.user && booking.user._id && booking.user._id.toString() === userId
                );
                
                
                if (matchingBookings.length > 0) {
                    const limitedBookings = matchingBookings.slice((options.page - 1) * options.limit, options.page * options.limit);
                    
                    return res.status(200).json({ 
                        bookings: limitedBookings,
                        currentPage: options.page,
                        totalPages: Math.ceil(matchingBookings.length / options.limit),
                        totalBookings: matchingBookings.length
                    });
                }
            }

            res.status(200).json({ 
                bookings,
                currentPage: options.page,
                totalPages: Math.ceil(totalBookings / options.limit),
                totalBookings
            });

        } catch (error) {
            console.error('Error fetching user bookings:', error);
            res.status(500).json({ message: 'Failed to fetch bookings', error: error.message });
        }
    },

    // GET /api/bookings/provider - Get bookings for the logged-in provider
    async getBookingsForProvider(req, res) {
        const providerId = req.auth.id;
        const { status, page = 1, limit = 10 } = req.query;


        try {
            // Verify the provider ID is a valid MongoDB ObjectId
            if (!mongoose.Types.ObjectId.isValid(providerId)) {
                return res.status(400).json({ message: 'Invalid provider ID format' });
            }

            // Create an ObjectId from the providerId string for proper MongoDB comparison
            const providerObjectId = new mongoose.Types.ObjectId(providerId);
            
            // Query with the ObjectId
            const query = { provider: providerObjectId };
            if (status) {
                query.status = status;
            }
            

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 },
                populate: { path: 'user', select: 'fullName email profilePictureUrl' } // Populate user details
            };

            // Log the query we're about to execute
            
            const bookings = await Booking.find(query)
                .populate('provider') // Fully populate provider to debug
                .populate(options.populate)
                .sort(options.sort)
                .skip((options.page - 1) * options.limit)
                .limit(options.limit);

            const totalBookings = await Booking.countDocuments(query);
            
            
            // Log the first booking to debug
            if (bookings.length > 0) {
            } else {
                // If no bookings found with direct query, try manual string comparison as fallback
                
                const allBookings = await Booking.find({})
                    .populate('provider')
                    .populate(options.populate);
                    
                const matchingBookings = allBookings.filter(booking => 
                    booking.provider && booking.provider._id && booking.provider._id.toString() === providerId
                );
                
                
                if (matchingBookings.length > 0) {
                    const limitedBookings = matchingBookings.slice((options.page - 1) * options.limit, options.page * options.limit);
                    
                    return res.status(200).json({ 
                        bookings: limitedBookings,
                        currentPage: options.page,
                        totalPages: Math.ceil(matchingBookings.length / options.limit),
                        totalBookings: matchingBookings.length
                    });
                }
            }
            
            res.status(200).json({ 
                bookings,
                currentPage: options.page,
                totalPages: Math.ceil(totalBookings / options.limit),
                totalBookings
            });

        } catch (error) {
            console.error('Error fetching provider bookings:', error);
            res.status(500).json({ message: 'Failed to fetch bookings', error: error.message });
        }
    },

    // GET /api/bookings/:id - Get a single booking by ID
    async getBookingById(req, res) {
        const bookingId = req.params.id;
        const userId = req.auth.id;
        const userType = req.auth.type;


        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
             return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        try {
            const booking = await Booking.findById(bookingId)
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider', 'fullName email serviceType profilePictureUrl averageRating');

            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }


            // TEMPORARY DEBUG OVERRIDE - allow any provider to view any booking (for testing only)
            const isDebugModeEnabled = true; // Set this to false in production!
            
            if (isDebugModeEnabled && userType === 'provider') {
                // No authorization check needed, allow access
            }
            // Normal authorization checks when debug mode is disabled
            else {
                // Authorization check: Ensure user or provider owns the booking
                if (userType === 'user' && booking.user._id.toString() !== userId) {
                    return res.status(403).json({ message: 'Forbidden: You do not own this booking.' });
                }
                if (userType === 'provider' && booking.provider._id.toString() !== userId) {
                    return res.status(403).json({ message: 'Forbidden: This booking is not assigned to you.' });
                }
            }

            res.status(200).json(booking);

        } catch (error) {
            console.error('Error fetching booking by ID:', error);
            res.status(500).json({ message: 'Failed to fetch booking', error: error.message });
        }
    },

    // PATCH /api/bookings/:id/status - Update booking status
    async updateBookingStatus(req, res) {
        const bookingId = req.params.id;
        const { status } = req.body;
        const userId = req.auth.id;
        const userType = req.auth.type;


        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
            return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        // Consider fetching allowed statuses from the model's enum definition
        const allowedStatuses = Booking.schema.path('status').enumValues;
        if (!status || !allowedStatuses.includes(status)) {
            return res.status(400).json({ message: `Invalid status provided. Allowed statuses: ${allowedStatuses.join(', ')}` });
        }

        try {
            // Find the booking and populate user and provider
            const booking = await Booking.findById(bookingId)
                .populate('user')
                .populate('provider');
                
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }


            // Authorization & State Transition Logic
            let canUpdate = false;
            const currentStatus = booking.status;

            // Convert all IDs to strings for comparison
            const bookingProviderId = booking.provider._id.toString();
            const bookingUserId = booking.user._id.toString();
            const requestUserId = userId.toString();


            // TEMPORARY DEBUG OVERRIDE - allow any provider to update status (for testing only)
            const isDebugModeEnabled = true; // Set this to false in production!
            
            if (isDebugModeEnabled && userType === 'provider') {
                
                // Provider status transitions in debug mode - allow any provider to update
                if (currentStatus === 'pending' && (status === 'accepted' || status === 'declined_by_provider')) {
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'in_progress') {
                    canUpdate = true;
                }
                else if (currentStatus === 'in_progress' && status === 'completed') {
                    canUpdate = true;
                }
            }
            // Normal authorization checks when debug mode is disabled
            else if (userType === 'provider' && bookingProviderId === requestUserId) {
                // Provider status transitions
                if (currentStatus === 'pending' && (status === 'accepted' || status === 'declined_by_provider')) {
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'in_progress') {
                    canUpdate = true;
                }
                else if (currentStatus === 'in_progress' && status === 'completed') {
                    canUpdate = true;
                }
                // Add more transitions if needed (e.g., accepted -> completed)
                 
            } else if (userType === 'user' && bookingUserId === requestUserId) {
                // User status transitions
                if (currentStatus === 'pending' && status === 'cancelled_by_user') {
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'cancelled_by_user') {
                    canUpdate = true;
                }
                // Users might be able to cancel accepted bookings under certain conditions (e.g., >24h before service)
                // else if (currentStatus === 'accepted' && status === 'cancelled_by_user' && /* check time condition */) canUpdate = true;
            }


            if (!canUpdate) {
                return res.status(403).json({
                    message: `Forbidden: Cannot change status from ${currentStatus} to ${status} for your role.`
                });
            }

            // Update the status
            booking.status = status;
            const updatedBooking = await booking.save();


            // Send push notification about the status change
            await BookingController.sendBookingStatusNotification(booking, status, userType);

            // Populate details for the response
            const populatedBooking = await Booking.findById(updatedBooking._id)
                .populate('user', 'fullName email')
                .populate('provider', 'fullName email serviceType');

            res.status(200).json(populatedBooking);

        } catch (error) {
            console.error('Error updating booking status:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation Error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update booking status', error: error.message });
        }
    },

    // Add a test method to fetch all bookings (temporary, for debugging)
    async getAllBookingsForTest(req, res) {
        try {
            
            // Fetch all bookings with populated references
            const bookings = await Booking.find({})
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider', 'fullName email serviceType profilePictureUrl')
                .sort({ serviceDateTime: -1 });
            
            
            if (bookings.length > 0) {
            }
            
            res.status(200).json({ 
                bookings,
                totalBookings: bookings.length
            });
        } catch (error) {
            console.error('TEST: Error fetching all bookings:', error);
            res.status(500).json({ message: 'Failed to fetch all bookings', error: error.message });
        }
    },

    // GET /api/bookings/by-user/:userId - Get bookings for a specific user ID (temporary debug endpoint)
    async getBookingsByUserId(req, res) {
        try {
            const userId = req.params.userId;
            
            if (!mongoose.Types.ObjectId.isValid(userId)) {
                return res.status(400).json({ message: 'Invalid user ID format' });
            }
            
            // Directly query by userId as a string to bypass any ObjectId issues
            const bookings = await Booking.find({})
                .populate('user')
                .populate('provider', 'fullName email serviceType profilePictureUrl');
            
            // Filter manually after populating to ensure correct string comparison
            const filteredBookings = bookings.filter(booking => 
                booking.user && booking.user._id && booking.user._id.toString() === userId
            );
            
            
            if (filteredBookings.length > 0) {
            }
            
            res.status(200).json({ 
                bookings: filteredBookings,
                totalBookings: filteredBookings.length
            });
        } catch (error) {
            console.error('Error in getBookingsByUserId:', error);
            res.status(500).json({ message: 'Failed to fetch bookings by user ID', error: error.message });
        }
    },

    // GET /api/bookings/by-provider/:providerId - Get bookings for a specific provider ID (temporary debug endpoint)
    async getBookingsByProviderId(req, res) {
        try {
            const providerId = req.params.providerId;
            
            if (!mongoose.Types.ObjectId.isValid(providerId)) {
                return res.status(400).json({ message: 'Invalid provider ID format' });
            }
            
            // Create an ObjectId from the provider ID string for proper MongoDB comparison
            const providerObjectId = new mongoose.Types.ObjectId(providerId);
            
            // Query with the ObjectId
            const query = { provider: providerObjectId };
            
            // Directly query by providerId 
            const bookings = await Booking.find(query)
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider')
                .sort({ serviceDateTime: -1 });
            
            
            if (bookings.length > 0) {
            }
            
            res.status(200).json({ 
                bookings,
                totalBookings: bookings.length
            });
        } catch (error) {
            console.error('Error in getBookingsByProviderId:', error);
            res.status(500).json({ message: 'Failed to fetch bookings by provider ID', error: error.message });
        }
    },

    // PATCH /api/bookings/:id/reassign - Reassign a booking to a different provider (debugging)
    async reassignBooking(req, res) {
        const bookingId = req.params.id;
        const { providerId } = req.body;
        
        
        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
            return res.status(400).json({ message: 'Invalid Booking ID format' });
        }
        
        if (!mongoose.Types.ObjectId.isValid(providerId)) {
            return res.status(400).json({ message: 'Invalid Provider ID format' });
        }
        
        try {
            // Verify the provider exists
            const providerExists = await Provider.findById(providerId);
            if (!providerExists) {
                return res.status(404).json({ message: 'Provider not found.' });
            }
            
            // Find the booking
            const booking = await Booking.findById(bookingId);
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }
            
            // Update the provider field
            const originalProvider = booking.provider;
            booking.provider = providerId;
            
            // Save the updated booking
            const updatedBooking = await booking.save();
            
            
            // Populate details for the response
            const populatedBooking = await Booking.findById(updatedBooking._id)
                .populate('user', 'fullName email')
                .populate('provider', 'fullName email serviceType');
            
            res.status(200).json(populatedBooking);
            
        } catch (error) {
            console.error('Error reassigning booking:', error);
            res.status(500).json({ message: 'Failed to reassign booking', error: error.message });
        }
    },

    // Send push notification for booking status changes
    async sendBookingStatusNotification(booking, status, actorType) {
        try {
            const userId = booking.user._id;
            const providerId = booking.provider._id;
            const userFullName = booking.user.fullName || 'User';
            const providerFullName = booking.provider.fullName || 'Provider';
            const serviceType = booking.provider.serviceType || 'service';
            const dateTime = new Date(booking.serviceDateTime).toLocaleString();

            let userNotification, providerNotification;

            switch (status) {
                case 'pending':
                    // New booking created (send to provider only)
                    providerNotification = {
                        title: 'New Booking Request',
                        body: `${userFullName} has requested your ${serviceType} services on ${dateTime}.`,
                        type: 'booking_created',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;

                case 'accepted':
                    // Booking accepted (send to user only)
                    userNotification = {
                        title: 'Booking Accepted',
                        body: `${providerFullName} has accepted your booking for ${serviceType} on ${dateTime}.`,
                        type: 'booking_accepted',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;

                case 'declined_by_provider':
                    // Booking declined (send to user only)
                    userNotification = {
                        title: 'Booking Declined',
                        body: `${providerFullName} has declined your booking for ${serviceType} on ${dateTime}.`,
                        type: 'booking_declined',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;

                case 'cancelled_by_user':
                    // Booking cancelled (send to provider only)
                    providerNotification = {
                        title: 'Booking Cancelled',
                        body: `${userFullName} has cancelled their booking for your ${serviceType} on ${dateTime}.`,
                        type: 'booking_cancelled',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;

                case 'in_progress':
                    // Service started (send to user only)
                    userNotification = {
                        title: 'Service Started',
                        body: `${providerFullName} has started their ${serviceType} service for your booking.`,
                        type: 'booking_started',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;

                case 'completed':
                    // Service completed (send to user only)
                    userNotification = {
                        title: 'Service Completed',
                        body: `${providerFullName} has completed their ${serviceType} service. Please rate your experience!`,
                        type: 'booking_completed',
                        data: {
                            bookingId: booking._id.toString(),
                            serviceType: serviceType,
                            serviceDateTime: booking.serviceDateTime.toISOString()
                        }
                    };
                    break;
            }

            // Send notifications
            const promises = [];
            if (userNotification) {
                promises.push(notificationService.sendNotification(userId, userNotification));
            }
            if (providerNotification) {
                promises.push(notificationService.sendNotificationToProvider(providerId, providerNotification));
            }

            await Promise.all(promises);
        } catch (error) {
            console.error('Error sending booking status notification:', error);
            // Don't throw the error to prevent blocking the main booking process
        }
    }
};

module.exports = BookingController; 