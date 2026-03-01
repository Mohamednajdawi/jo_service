const bcrypt = require('bcryptjs');
const { generateToken } = require('../utils/jwt.utils');
const Provider = require('../models/provider.model');
const User = require('../models/user.model');
const Booking = require('../models/booking.model');
const mongoose = require('mongoose');

// Admin credentials (in production, store in database)
const ADMIN_CREDENTIALS = [
  {
    email: 'amer@joservice.com',
    password: 'Amer&1234'
  },
  {
    email: 'mohammed@joservice.com',
    password: 'Moh&1234'
  }
];

/**
 * Admin login
 */
const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate credentials against multiple admin accounts
    const adminAccount = ADMIN_CREDENTIALS.find(admin => 
      admin.email === email && admin.password === password
    );
    
    if (!adminAccount) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin credentials'
      });
    }

    // Generate admin token
    const adminToken = generateToken({
      id: 'admin',
      type: 'admin',
      email: email,
      role: 'admin'
    });

    res.status(200).json({
      success: true,
      message: 'Admin login successful',
      token: adminToken,
      user: {
        id: 'admin',
        email: email,
        role: 'admin'
      }
    });

  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Get all providers with pagination and filtering
 */
const getAllProviders = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      status, 
      serviceType, 
      city,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    if (status) filter.verificationStatus = status;
    if (serviceType) filter.serviceType = new RegExp(serviceType, 'i');
    if (city) filter['location.city'] = new RegExp(city, 'i');

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Get providers with pagination
    const providers = await Provider.find(filter)
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit))
      .select('-password'); // Exclude password field

    // Get total count for pagination
    const totalProviders = await Provider.countDocuments(filter);
    const totalPages = Math.ceil(totalProviders / parseInt(limit));

    // Add computed fields for admin dashboard
    const enrichedProviders = providers.map(provider => {
      const providerObj = provider.toObject();
      return {
        ...providerObj,
        joinedDate: providerObj.createdAt,
        rating: providerObj.averageRating || 0,
        completedJobs: providerObj.completedBookings || 0,
        lastActive: providerObj.updatedAt,
        verificationStatus: providerObj.verificationStatus || 'pending'
      };
    });

    res.status(200).json({
      success: true,
      data: {
        providers: enrichedProviders,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalProviders,
          hasNext: parseInt(page) < totalPages,
          hasPrev: parseInt(page) > 1
        }
      }
    });

  } catch (error) {
    console.error('Get all providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch providers',
      error: error.message
    });
  }
};

/**
 * Update provider verification status
 */
const updateProviderStatus = async (req, res) => {
  try {
    const { providerId } = req.params;
    const { status, rejectionReason } = req.body;


    // Validate status
    const validStatuses = ['pending', 'verified', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification status'
      });
    }

    // Get current provider to track status change
    const currentProvider = await Provider.findById(providerId).select('verificationStatus');
    if (!currentProvider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    const previousStatus = currentProvider.verificationStatus || 'pending';
    const adminInfo = req.auth.userId || req.auth.email || 'admin';

    // Build update object
    const updateData = {
      verificationStatus: status,
      isVerified: status === 'verified', // Sync the boolean field
      verifiedAt: status === 'verified' ? new Date() : null,
      verifiedBy: adminInfo,
    };

    // Handle rejection reason
    if (status === 'rejected') {
      // Add rejection reason if provided, or keep existing one
      if (rejectionReason) {
        updateData.rejectionReason = rejectionReason;
      }
    } else {
      // Clear rejection reason when status changes away from rejected
      updateData.rejectionReason = null;
    }

    // Add status change history (optional enhancement)
    updateData.lastStatusChange = new Date();
    updateData.lastStatusChangedBy = adminInfo;

    // Update provider
    const updatedProvider = await Provider.findByIdAndUpdate(
      providerId,
      updateData,
      { new: true, select: '-password' }
    );

    if (!updatedProvider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    // Log the status change for admin transparency
    console.log({
      providerId,
      providerName: updatedProvider.fullName || updatedProvider.companyName,
      previousStatus,
      newStatus: status,
      changedBy: adminInfo,
      timestamp: new Date().toISOString(),
      rejectionReason: status === 'rejected' ? rejectionReason : null
    });

    // TODO: Send notification to provider about status change
    // This could be email, push notification, etc.

    res.status(200).json({
      success: true,
      message: `Provider status updated from ${previousStatus} to ${status}`,
      data: {
        ...updatedProvider.toObject(),
        statusChangeHistory: {
          previousStatus,
          newStatus: status,
          changedBy: adminInfo,
          changedAt: new Date()
        }
      }
    });

  } catch (error) {
    console.error('Update provider status error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to update provider status',
      error: error.message
    });
  }
};

/**
 * Get provider details by ID
 */
const getProviderById = async (req, res) => {
  try {
    const { providerId } = req.params;

    const provider = await Provider.findById(providerId).select('-password');

    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    // Enrich with computed fields
    const enrichedProvider = {
      ...provider.toObject(),
      joinedDate: provider.createdAt,
      rating: provider.averageRating || 0,
      completedJobs: provider.completedBookings || 0,
      lastActive: provider.updatedAt,
      verificationStatus: provider.verificationStatus || 'pending'
    };

    res.status(200).json({
      success: true,
      data: enrichedProvider
    });

  } catch (error) {
    console.error('Get provider by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch provider details',
      error: error.message
    });
  }
};

/**
 * Get admin dashboard statistics
 */
const getDashboardStats = async (req, res) => {
  try {
    // Get provider statistics
    const totalProviders = await Provider.countDocuments();
    const pendingProviders = await Provider.countDocuments({ verificationStatus: 'pending' });
    const verifiedProviders = await Provider.countDocuments({ verificationStatus: 'verified' });
    const rejectedProviders = await Provider.countDocuments({ verificationStatus: 'rejected' });

    // Get user statistics
    const totalUsers = await User.countDocuments();

    // Get recent providers (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentProviders = await Provider.countDocuments({
      createdAt: { $gte: sevenDaysAgo }
    });

    // Get service type distribution
    const serviceTypeStats = await Provider.aggregate([
      { $group: { _id: '$serviceType', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Get city distribution
    const cityStats = await Provider.aggregate([
      { $group: { _id: '$location.city', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    res.status(200).json({
      success: true,
      data: {
        overview: {
          totalProviders,
          totalUsers,
          recentProviders
        },
        providerStatus: {
          pending: pendingProviders,
          verified: verifiedProviders,
          rejected: rejectedProviders
        },
        serviceTypes: serviceTypeStats,
        cities: cityStats
      }
    });

  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard statistics',
      error: error.message
    });
  }
};

/**
 * Bulk update provider statuses
 */
const bulkUpdateProviders = async (req, res) => {
  try {
    const { providerIds, status, rejectionReason } = req.body;

    // Validate input
    if (!Array.isArray(providerIds) || providerIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Provider IDs array is required'
      });
    }

    const validStatuses = ['pending', 'verified', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification status'
      });
    }

    // Build update object
    const updateData = {
      verificationStatus: status,
      isVerified: status === 'verified', // Sync the boolean field
      verifiedAt: status === 'verified' ? new Date() : null,
      verifiedBy: req.auth.userId || req.auth.email || 'admin'
    };

    if (status === 'rejected' && rejectionReason) {
      updateData.rejectionReason = rejectionReason;
    }

    // Bulk update
    const result = await Provider.updateMany(
      { _id: { $in: providerIds } },
      updateData
    );

    res.status(200).json({
      success: true,
      message: `${result.modifiedCount} providers updated to ${status}`,
      data: {
        matched: result.matchedCount,
        modified: result.modifiedCount
      }
    });

  } catch (error) {
    console.error('Bulk update providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk update providers',
      error: error.message
    });
  }
};

// Create provider (admin only)
const createProvider = async (req, res) => {
  try {
    const {
      fullName,
      email,
      password,
      phoneNumber,
      serviceType,
      services,
      businessName,
      hourlyRate,
      location,
      availability,
      description
    } = req.body;

    // Validate required fields
    if (!fullName || !email || !password || !phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Full name, email, password, and phone number are required'
      });
    }

    // Validate serviceType (required by Provider model)
    let finalServiceType = serviceType;
    if (!finalServiceType && services && Array.isArray(services) && services.length > 0) {
      finalServiceType = services[0]; // Use first service from array if serviceType not provided
    }
    
    if (!finalServiceType) {
      return res.status(400).json({
        success: false,
        message: 'Service type is required'
      });
    }

    // Validate email domain
    if (!email.endsWith('@joprovider.com')) {
      return res.status(400).json({
        success: false,
        message: 'Provider email must be from @joprovider.com domain'
      });
    }

    // Check if provider already exists
    const existingProvider = await Provider.findOne({ email });
    if (existingProvider) {
      return res.status(400).json({
        success: false,
        message: 'Provider with this email already exists'
      });
    }

    // Create new provider
    const provider = new Provider({
      fullName,
      email,
      password,
      phoneNumber,
      serviceType: finalServiceType,
      businessName: businessName || '',
      hourlyRate: hourlyRate || 0,
      location: location || {},
      availability: availability || {},
      serviceDescription: description || '',
      verificationStatus: 'verified', // Admin-created providers are pre-verified
      isVerified: true, // Sync the boolean field
      verifiedAt: new Date(),
      verifiedBy: req.auth.userId || req.auth.email || 'admin'
    });

    await provider.save();

    // Remove password from response
    const providerResponse = provider.toObject();
    delete providerResponse.password;

    res.status(201).json({
      success: true,
      message: 'Provider created successfully',
      data: providerResponse
    });

  } catch (error) {
    console.error('Create provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create provider',
      error: error.message
    });
  }
};

/**
 * Get all bookings with comprehensive filtering and monitoring
 */
const getAllBookings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      providerId,
      userId,
      startDate,
      endDate,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build query filters
    const query = {};
    
    if (status) {
      query.status = status;
    }
    
    if (providerId && mongoose.Types.ObjectId.isValid(providerId)) {
      query.provider = new mongoose.Types.ObjectId(providerId);
    }
    
    if (userId && mongoose.Types.ObjectId.isValid(userId)) {
      query.user = new mongoose.Types.ObjectId(userId);
    }
    
    // Date range filter
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        query.createdAt.$lte = new Date(endDate);
      }
    }

    // Pagination options
    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { [sortBy]: sortOrder === 'desc' ? -1 : 1 },
      populate: [
        {
          path: 'user',
          select: 'fullName email phoneNumber profilePictureUrl createdAt'
        },
        {
          path: 'provider',
          select: 'fullName email phoneNumber businessName serviceType averageRating totalRatings profilePictureUrl verificationStatus'
        }
      ]
    };

    // Get bookings with pagination
    const bookings = await Booking.find(query)
      .populate(options.populate)
      .sort(options.sort)
      .limit(options.limit * 1)
      .skip((options.page - 1) * options.limit)
      .exec();

    // Get total count for pagination
    const totalBookings = await Booking.countDocuments(query);

    // Get booking statistics
    const stats = await Booking.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const statusStats = {};
    stats.forEach(stat => {
      statusStats[stat._id] = stat.count;
    });

    res.status(200).json({
      success: true,
      data: {
        bookings,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalBookings / options.limit),
          totalBookings,
          hasNext: page < Math.ceil(totalBookings / options.limit),
          hasPrev: page > 1
        },
        statistics: {
          statusBreakdown: statusStats,
          totalBookings
        }
      }
    });

  } catch (error) {
    console.error('Error fetching bookings for admin:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bookings',
      error: error.message
    });
  }
};

/**
 * Get detailed booking analytics and insights
 */
const getBookingAnalytics = async (req, res) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    // Calculate date range based on timeframe
    let startDate = new Date();
    switch (timeframe) {
      case '7d':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(startDate.getDate() - 30);
        break;
      case '90d':
        startDate.setDate(startDate.getDate() - 90);
        break;
      case '1y':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default:
        startDate.setDate(startDate.getDate() - 30);
    }

    // Get booking trends over time
    const bookingTrends = await Booking.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            status: '$status'
          },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { '_id.date': 1 }
      }
    ]);

    // Get provider performance metrics
    const providerMetrics = await Booking.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: '$provider',
          totalBookings: { $sum: 1 },
          acceptedBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'accepted'] }, 1, 0] }
          },
          completedBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          cancelledBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled_by_user'] }, 1, 0] }
          },
          declinedBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'declined_by_provider'] }, 1, 0] }
          }
        }
      },
      {
        $lookup: {
          from: 'providers',
          localField: '_id',
          foreignField: '_id',
          as: 'providerInfo'
        }
      },
      {
        $unwind: '$providerInfo'
      },
      {
        $addFields: {
          acceptanceRate: {
            $cond: [
              { $gt: ['$totalBookings', 0] },
              { $multiply: [{ $divide: ['$acceptedBookings', '$totalBookings'] }, 100] },
              0
            ]
          },
          completionRate: {
            $cond: [
              { $gt: ['$acceptedBookings', 0] },
              { $multiply: [{ $divide: ['$completedBookings', '$acceptedBookings'] }, 100] },
              0
            ]
          }
        }
      },
      {
        $sort: { totalBookings: -1 }
      },
      {
        $limit: 10
      }
    ]);

    // Get user activity metrics
    const userMetrics = await Booking.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: '$user',
          totalBookings: { $sum: 1 },
          completedBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          cancelledBookings: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled_by_user'] }, 1, 0] }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'userInfo'
        }
      },
      {
        $unwind: '$userInfo'
      },
      {
        $sort: { totalBookings: -1 }
      },
      {
        $limit: 10
      }
    ]);

    // Get overall statistics
    const overallStats = await Booking.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: null,
          totalBookings: { $sum: 1 },
          avgResponseTime: { $avg: { $subtract: ['$updatedAt', '$createdAt'] } },
          statusBreakdown: {
            $push: '$status'
          }
        }
      }
    ]);

    res.status(200).json({
      success: true,
      data: {
        timeframe,
        bookingTrends,
        providerMetrics,
        userMetrics,
        overallStats: overallStats[0] || {}
      }
    });

  } catch (error) {
    console.error('Error fetching booking analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking analytics',
      error: error.message
    });
  }
};

/**
 * Get booking activity feed (real-time monitoring)
 */
const getBookingActivityFeed = async (req, res) => {
  try {
    const { limit = 50 } = req.query;

    // Get recent booking activities (status changes, new bookings, etc.)
    const recentBookings = await Booking.find({})
      .populate('user', 'fullName email')
      .populate('provider', 'fullName email serviceType')
      .sort({ updatedAt: -1 })
      .limit(parseInt(limit))
      .exec();

    // Transform data for activity feed
    const activityFeed = recentBookings.map(booking => {
      const timeSinceUpdate = Date.now() - booking.updatedAt.getTime();
      const isRecent = timeSinceUpdate < 3600000; // Less than 1 hour
      
      return {
        id: booking._id,
        type: 'booking_status_change',
        status: booking.status,
        timestamp: booking.updatedAt,
        isRecent,
        user: {
          id: booking.user._id,
          name: booking.user.fullName,
          email: booking.user.email
        },
        provider: {
          id: booking.provider._id,
          name: booking.provider.fullName,
          email: booking.provider.email,
          serviceType: booking.provider.serviceType
        },
        serviceDateTime: booking.serviceDateTime,
        createdAt: booking.createdAt,
        description: generateActivityDescription(booking)
      };
    });

    res.status(200).json({
      success: true,
      data: {
        activities: activityFeed,
        totalCount: activityFeed.length
      }
    });

  } catch (error) {
    console.error('Error fetching booking activity feed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch activity feed',
      error: error.message
    });
  }
};

/**
 * Get specific booking details for admin review
 */
const getBookingDetails = async (req, res) => {
  try {
    const { bookingId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format'
      });
    }

    const booking = await Booking.findById(bookingId)
      .populate({
        path: 'user',
        select: 'fullName email phoneNumber profilePictureUrl createdAt'
      })
      .populate({
        path: 'provider',
        select: 'fullName email phoneNumber businessName serviceType serviceDescription hourlyRate averageRating totalRatings profilePictureUrl verificationStatus location'
      })
      .exec();

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Get related messages/chat history if needed
    const Message = require('../models/message.model');
    const conversationId = [booking.user._id, booking.provider._id].sort().join('_');
    
    const messages = await Message.find({ conversationId })
      .sort({ timestamp: 1 })
      .limit(20)
      .exec();

    res.status(200).json({
      success: true,
      data: {
        booking,
        messages,
        timeline: generateBookingTimeline(booking)
      }
    });

  } catch (error) {
    console.error('Error fetching booking details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking details',
      error: error.message
    });
  }
};

/**
 * Helper function to generate activity descriptions
 */
function generateActivityDescription(booking) {
  const userName = booking.user.fullName;
  const providerName = booking.provider.fullName;
  const serviceType = booking.provider.serviceType;
  
  switch (booking.status) {
    case 'pending':
      return `${userName} requested ${serviceType} service from ${providerName}`;
    case 'accepted':
      return `${providerName} accepted ${userName}'s ${serviceType} booking`;
    case 'declined_by_provider':
      return `${providerName} declined ${userName}'s ${serviceType} booking`;
    case 'cancelled_by_user':
      return `${userName} cancelled their ${serviceType} booking with ${providerName}`;
    case 'in_progress':
      return `${serviceType} service started between ${userName} and ${providerName}`;
    case 'completed':
      return `${serviceType} service completed between ${userName} and ${providerName}`;
    default:
      return `Booking status updated to ${booking.status}`;
  }
}

/**
 * Helper function to generate booking timeline
 */
function generateBookingTimeline(booking) {
  const timeline = [
    {
      status: 'pending',
      timestamp: booking.createdAt,
      description: 'Booking request created',
      isCompleted: true
    }
  ];

  // Add current status if different from pending
  if (booking.status !== 'pending') {
    timeline.push({
      status: booking.status,
      timestamp: booking.updatedAt,
      description: generateStatusDescription(booking.status),
      isCompleted: true
    });
  }

  return timeline;
}

/**
 * Helper function to generate status descriptions
 */
function generateStatusDescription(status) {
  switch (status) {
    case 'accepted':
      return 'Provider accepted the booking';
    case 'declined_by_provider':
      return 'Provider declined the booking';
    case 'cancelled_by_user':
      return 'User cancelled the booking';
    case 'in_progress':
      return 'Service is in progress';
    case 'completed':
      return 'Service completed successfully';
    default:
      return `Status changed to ${status}`;
  }
}

module.exports = {
  adminLogin,
  getAllProviders,
  updateProviderStatus,
  getProviderById,
  getDashboardStats,
  bulkUpdateProviders,
  createProvider,
  // New booking management functions
  getAllBookings,
  getBookingAnalytics,
  getBookingActivityFeed,
  getBookingDetails
};
