const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// Forward declaration for Provider model to avoid circular dependency issues if methods are complex.
// However, for simple updates like averageRating, direct model usage is fine.
// const Provider = mongoose.model('Provider'); 

const ratingSchema = new Schema({
    booking: {
        type: Schema.Types.ObjectId,
        ref: 'Booking',
        required: true
    },
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    provider: {
        type: Schema.Types.ObjectId,
        ref: 'Provider',
        required: true
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    review: {
        type: String,
        required: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

// Create a compound index to ensure a user can only rate a booking once
ratingSchema.index({ booking: 1, user: 1 }, { unique: true });

// Method to calculate average rating for a provider
ratingSchema.statics.calculateAverageRating = async function(providerId) {
    const result = await this.aggregate([
        { $match: { provider: new mongoose.Types.ObjectId(providerId) } },
        { 
            $group: { 
                _id: "$provider", 
                averageRating: { $avg: "$rating" },
                totalRatings: { $sum: 1 }
            } 
        }
    ]);
    
    if (result.length > 0) {
        return {
            averageRating: result[0].averageRating,
            totalRatings: result[0].totalRatings
        };
    }
    
    return { averageRating: 0, totalRatings: 0 };
};

// Static method to calculate and update the provider's average rating
ratingSchema.statics.calculateAndUpdateProviderRating = async function(providerId) {
    if (!providerId) return;

    // We need to import Provider model here to avoid compile-time circular dependencies
    // if this file is imported by Provider model directly or indirectly.
    // However, if Rating model is only used by controllers/services, it's usually fine at the top.
    const Provider = mongoose.model('Provider');

    const stats = await this.aggregate([
        {
            $match: { provider: new mongoose.Types.ObjectId(providerId) }
        },
        {
            $group: {
                _id: '$provider',
                averageRating: { $avg: '$rating' },
                totalRatings: { $sum: 1 }
            }
        }
    ]);

    try {
        if (stats.length > 0) {
            await Provider.findByIdAndUpdate(providerId, {
                averageRating: parseFloat(stats[0].averageRating.toFixed(2)), // Round to 2 decimal places
                totalRatings: stats[0].totalRatings
            });
        } else {
            // No ratings found, reset provider's rating fields
            await Provider.findByIdAndUpdate(providerId, {
                averageRating: 0,
                totalRatings: 0
            });
        }
    } catch (error) {
        console.error(`Error updating provider rating for ${providerId}:`, error);
        // Decide if this error should be propagated or just logged
    }
};

// Middleware to update provider rating after a new rating is saved
ratingSchema.post('save', async function(doc, next) {
    // 'this' refers to the document that was saved
    // We need to access the constructor to call the static method
    await this.constructor.calculateAndUpdateProviderRating(this.provider);
    next();
});

// Middleware to update provider rating after a rating is removed
// Note: findByIdAndRemove, findOneAndRemove trigger 'findOneAndRemove' hook, not 'remove'.
// For operations like deleteMany, remove, this hook won't run.
// Ensure to call calculateAndUpdateProviderRating manually if using such methods.
ratingSchema.post('findOneAndRemove', async function(doc, next) {
    // 'doc' is the document that was removed
    if (doc) {
        // Access the model via doc.constructor
        await doc.constructor.calculateAndUpdateProviderRating(doc.provider);
    }
    next();
});
// If you use .remove() on a document instance, you'd use:
// ratingSchema.post('remove', async function(doc, next) { ... });


const Rating = mongoose.model('Rating', ratingSchema);

module.exports = Rating; 