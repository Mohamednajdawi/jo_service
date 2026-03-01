const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '.env') });

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
    console.error("FATAL ERROR: MONGODB_URI is not defined in .env file.");
    process.exit(1); // Exit the application if DB connection string is missing
}

const connectDB = async () => {
    try {
        await mongoose.connect(MONGODB_URI, {
            // Mongoose 6+ no longer requires most of these options, but good to be aware of past ones
            // useNewUrlParser: true, // Deprecated
            // useUnifiedTopology: true, // Deprecated
            // useCreateIndex: true, // Deprecated
            // useFindAndModify: false, // Deprecated
        });
        console.log('MongoDB Connected successfully!');
    } catch (error) {
        console.error('MongoDB connection error:', error.message);
        // Exit process with failure
        process.exit(1);
    }
};

// Handle Mongoose connection events (optional, but good for debugging)
mongoose.connection.on('connected', () => {
    console.log('MongoDB connection established');
});

mongoose.connection.on('disconnected', () => {
    console.log('MongoDB connection disconnected');
});

mongoose.connection.on('error', (err) => {
    console.error('MongoDB connection error:', err);
});

// If the Node process ends, close the Mongoose connection
process.on('SIGINT', async () => {
    await mongoose.connection.close();
    process.exit(0);
});

module.exports = connectDB; 