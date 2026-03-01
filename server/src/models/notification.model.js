const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    recipient: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'recipientModel'
    },
    recipientModel: {
        type: String,
        required: true,
        enum: ['User', 'Provider']
    },
    type: {
        type: String,
        required: true,
        enum: [
            'booking_created',
            'booking_accepted',
            'booking_declined',
            'booking_cancelled',
            'booking_in_progress',
            'booking_completed',
            'new_message',
            'new_rating',
            'payment_received',
            'system_notification'
        ]
    },
    title: {
        type: String,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    relatedBooking: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Booking',
        required: false
    },
    relatedMessage: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Message',
        required: false
    },
    isRead: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

// Index to help with querying notifications efficiently
notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, isRead: 1 });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification; 