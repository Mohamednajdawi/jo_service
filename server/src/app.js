const path = require('path'); // Import path module
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const express = require('express');
const http = require('http'); // Import http module
const { WebSocketServer } = require('ws'); // Import WebSocketServer
const connectDB = require('./config/db'); // Import the Mongoose connection function
const cors = require('cors'); // Import cors
const { initializeWebSocket } = require('./services/websocket.service'); // Import WebSocket initializer

// Swagger documentation
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swagger');

// Connect to Database
connectDB();

const app = express();
const PORT = process.env.PORT || 3000;

// Import Routers
const authRoutes = require('./routes/auth.routes');
const bookingRoutes = require('./routes/booking.routes'); // Import booking routes
const providerRoutes = require('./routes/provider.routes'); // Import provider routes
const userRoutes = require('./routes/user.routes'); // Import user routes
const chatRoutes = require('./routes/chat.routes'); // Import chat routes
const ratingRoutes = require('./routes/rating.routes');
const notificationRoutes = require('./routes/notification.routes');
const adminRoutes = require('./routes/admin.routes'); // Import admin routes

app.use(cors()); // Enable CORS for all routes
app.use(express.json()); // Middleware to parse JSON bodies

// Serve static files from the 'public' directory
app.use('/uploads', express.static(path.join(__dirname, '..', 'public', 'uploads')));
app.use(express.static(path.join(__dirname, '..', 'public'))); // Serve other static files

// Swagger documentation route
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'JO Service API Documentation'
}));

// Basic route for testing
app.get('/', (req, res) => {
  res.send('Hello from the On-Demand Service Marketplace API!');
});

// Email verification page route
app.get('/verify-email', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'verify-email.html'));
});

// Mount Routers
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes); // Mount booking routes
app.use('/api/providers', providerRoutes); // Mount provider routes
app.use('/api/users', userRoutes); // Mount user routes
app.use('/api/chats', chatRoutes); // Mount chat routes
app.use('/api/ratings', ratingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes); // Mount admin routes

// TODO: Add routes for ratings etc.

// --- Create HTTP and WebSocket Servers ---
const server = http.createServer(app); 
initializeWebSocket(server); // Initialize WebSocket handling
console.log('WebSocket server initialized');

// --- Start the HTTP server ---
server.listen(PORT, '0.0.0.0', () => { 
    console.log(`🚀 Server (HTTP + WebSocket) is running on port ${PORT}`);
    console.log(`📚 API Documentation available at: http://localhost:${PORT}/api-docs`);
    console.log(`📱 Mobile app can connect at: http://10.46.6.68:${PORT}`);
    console.log(`🌐 Network accessible at: http://10.46.6.68:${PORT}`);
});

module.exports = app; // Keep exporting app for potential testing 