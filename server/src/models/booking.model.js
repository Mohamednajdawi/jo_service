const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const bookingSchema = new Schema({
    user: { 
        type: Schema.Types.ObjectId, 
        ref: 'User', // Reference to the User model
        required: true,
        index: true // Index for faster queries by user
    },
    provider: {
        type: Schema.Types.ObjectId,
        ref: 'Provider', // Reference to the Provider model
        required: true,
        index: true // Index for faster queries by provider
    },
    serviceDateTime: {
        type: Date,
        required: [true, 'Service date and time are required']
    },
    serviceLocationDetails: {
        type: String,
        trim: true
    },
    userNotes: {
        type: String,
        trim: true
    },
    photos: {
        type: [String], // Array of photo URLs
        default: []
    },
    status: {
        type: String,
        required: true,
        enum: [
            'pending',            // Initial request by user
            'accepted',           // Confirmed by provider
            'declined_by_provider',// Rejected by provider
            'cancelled_by_user',  // Cancelled by user before acceptance/service
            'in_progress',        // Service ongoing
            'completed',          // Service finished
            'payment_due',        // Optional: If payment integration added
            'paid'                // Optional: If payment integration added
        ],
        default: 'pending',
        index: true // Index for filtering by status
    },
    // Optional: Add pricing details if calculated/stored at booking time
    // estimatedCost: { type: Number },
    // finalCost: { type: Number }

}, { timestamps: true }); // Adds createdAt and updatedAt

// Optional: Compound index if often querying by user and status, or provider and status
// bookingSchema.index({ user: 1, status: 1 });
// bookingSchema.index({ provider: 1, status: 1 });

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;