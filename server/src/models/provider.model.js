const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Schema = mongoose.Schema;

const SALT_ROUNDS = 10;

// Define valid service categories
const validServiceCategories = [
    'cleaning',
    'home_repair',
    'plumbing',
    'electrical',
    'gardening',
    'moving',
    'tutoring',
    'pet_care',
    'beauty',
    'wellness',
    'photography',
    'graphic_design',
    'web_development',
    'legal',
    'automotive',
    'event_planning',
    'personal_training',
    'cooking',
    'delivery',
    'other'
];

// Define the location schema with GeoJSON point
const locationSchema = new Schema({
    type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
    },
    coordinates: {
        type: [Number], // [longitude, latitude]
        required: true
    },
    address: {
        type: String,
        trim: true
    },
    city: {
        type: String,
        trim: true
    },
    state: {
        type: String,
        trim: true
    },
    zipCode: {
        type: String,
        trim: true
    },
    country: {
        type: String,
        trim: true,
        default: 'US'
    }
});

// Provider schema
const providerSchema = new Schema({
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        trim: true,
        lowercase: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please provide a valid email address']
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters long']
    },
    fullName: {
        type: String,
        required: [true, 'Full name is required'],
        trim: true
    },
    phoneNumber: {
        type: String,
        trim: true
    },
    profilePictureUrl: {
        type: String,
        default: null
    },
    businessName: {
        type: String,
        trim: true
    },
    serviceType: {
        type: String,
        required: [true, 'Service type is required'],
        trim: true
    },
    serviceDescription: {
        type: String,
        trim: true
    },
    serviceCategory: {
        type: String,
        enum: validServiceCategories,
        default: 'other'
    },
    serviceTags: [{
        type: String,
        trim: true
    }],
    hourlyRate: {
        type: Number,
        min: 0
    },
    location: {
        type: locationSchema,
        default: null
    },
    // Service areas where the provider operates - could be zip codes or city names
    serviceAreas: [{
        type: String,
        trim: true
    }],
    // Days and hours when the provider is available
    availability: {
        monday: { type: [String], default: [] },
        tuesday: { type: [String], default: [] },
        wednesday: { type: [String], default: [] },
        thursday: { type: [String], default: [] },
        friday: { type: [String], default: [] },
        saturday: { type: [String], default: [] },
        sunday: { type: [String], default: [] }
    },
    averageRating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalRatings: {
        type: Number,
        default: 0,
        min: 0
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    // Admin verification fields
    verificationStatus: {
        type: String,
        enum: ['pending', 'verified', 'rejected'],
        default: 'pending'
    },
    verifiedAt: {
        type: Date,
        default: null
    },
    verifiedBy: {
        type: String, // Admin ID or username
        default: null
    },
    rejectionReason: {
        type: String,
        trim: true,
        default: null
    },
    // Status change tracking
    lastStatusChange: {
        type: Date,
        default: Date.now
    },
    lastStatusChangedBy: {
        type: String, // Admin ID or username who made the last change
        default: null
    },
    completedBookings: {
        type: Number,
        default: 0,
        min: 0
    },
    accountStatus: {
        type: String,
        enum: ['active', 'suspended', 'deactivated'],
        default: 'active'
    },
    isAvailable: {
        type: Boolean,
        default: true
    },
    fcmToken: {
        type: String,
        trim: true,
        default: null
    },
    notificationSettings: {
        bookingUpdates: { type: Boolean, default: true },
        chatMessages: { type: Boolean, default: true },
        ratings: { type: Boolean, default: true },
        promotions: { type: Boolean, default: true }
    },
    // Fields to track document history
    createdAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true, // Adds createdAt and updatedAt fields
});

// Create a 2dsphere index on the location field for geospatial queries
providerSchema.index({ 'location.coordinates': '2dsphere' });

// Create a text index for searching providers by various fields
providerSchema.index({ 
    fullName: 'text',
    businessName: 'text',
    serviceType: 'text',
    serviceDescription: 'text',
    serviceTags: 'text'
}, {
    weights: {
        businessName: 10,
        serviceType: 8,
        fullName: 5,
        serviceTags: 4,
        serviceDescription: 3
    },
    name: 'provider_text_index'
});

// Create an index on service category for category filtering
providerSchema.index({ serviceCategory: 1 });

// Create an index on rating for sorting
providerSchema.index({ averageRating: -1 });

// Method to update the provider's location
providerSchema.methods.updateLocation = async function(locationData) {
    if (!locationData || !locationData.coordinates || locationData.coordinates.length !== 2) {
        throw new Error('Invalid location data');
    }
    
    this.location = {
        type: 'Point',
        coordinates: locationData.coordinates,
        address: locationData.address,
        city: locationData.city,
        state: locationData.state,
        zipCode: locationData.zipCode,
        country: locationData.country || 'US'
    };
    
    return await this.save();
};

// Pre-save hook to hash password
providerSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    try {
        const salt = await bcrypt.genSalt(SALT_ROUNDS);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Method to compare input password with hashed password
providerSchema.methods.comparePassword = async function(inputPassword) {
    return await bcrypt.compare(inputPassword, this.password);
};

const Provider = mongoose.model('Provider', providerSchema);

module.exports = Provider; 