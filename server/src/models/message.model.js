const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    // Composite ID combining the two participants, sorted alphabetically
    // Ensures uniqueness and easy querying for a conversation
    conversationId: {
        type: String,
        required: true,
        index: true, 
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'senderType' // Dynamic ref based on senderType
    },
    senderType: {
        type: String,
        required: true,
        enum: ['User', 'Provider'] // Or use the actual model names if preferred
    },
    recipientId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'recipientType' // Dynamic ref based on recipientType
    },
     recipientType: {
        type: String,
        required: true,
        enum: ['User', 'Provider']
    },
    messageType: {
        type: String,
        enum: ['text', 'image', 'booking_images'],
        default: 'text'
    },
    text: {
        type: String,
        required: function() {
            return this.messageType === 'text' || (this.messageType === 'image' && (!this.images || this.images.length === 0));
        },
        trim: true
    },
    images: {
        type: [String], // Array of image URLs
        default: []
    },
    timestamp: {
        type: Date,
        default: Date.now,
        index: true
    },
    // Optional: read status for features like 'seen' indicators
    isRead: {
        type: Boolean,
        default: false
    },
    readAt: {
        type: Date
    }
}, {
    timestamps: true // Adds createdAt and updatedAt automatically
});

// Helper static method to generate the conversation ID consistently
messageSchema.statics.generateConversationId = function(id1, id2) {
    // Sort IDs alphabetically to ensure consistency regardless of sender/recipient order
    const ids = [id1.toString(), id2.toString()].sort();
    return ids.join('_');
};

const Message = mongoose.model('Message', messageSchema);

module.exports = Message; 