const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'JO Service Marketplace API',
      version: '1.0.0',
      description: 'API documentation for the On-Demand Service Marketplace',
      contact: {
        name: 'API Support',
        email: 'support@joservice.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Development server'
      },
      {
        url: 'https://your-app-name.onrender.com/api',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            email: { type: 'string', format: 'email' },
            fullName: { type: 'string' },
            phoneNumber: { type: 'string' },
            profilePictureUrl: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        Provider: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            email: { type: 'string', format: 'email' },
            fullName: { type: 'string' },
            businessName: { type: 'string' },
            serviceType: { type: 'string' },
            serviceDescription: { type: 'string' },
            serviceCategory: { type: 'string' },
            hourlyRate: { type: 'number' },
            averageRating: { type: 'number' },
            totalRatings: { type: 'number' },
            isVerified: { type: 'boolean' },
            location: {
              type: 'object',
              properties: {
                coordinates: { type: 'array', items: { type: 'number' } },
                address: { type: 'string' },
                city: { type: 'string' }
              }
            }
          }
        },
        Booking: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            user: { type: 'string' },
            provider: { type: 'string' },
            serviceDateTime: { type: 'string', format: 'date-time' },
            serviceLocationDetails: { type: 'string' },
            userNotes: { type: 'string' },
            status: { 
              type: 'string', 
              enum: ['pending', 'accepted', 'declined_by_provider', 'cancelled_by_user', 'in_progress', 'completed', 'payment_due', 'paid']
            },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        Rating: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            booking: { type: 'string' },
            user: { type: 'string' },
            provider: { type: 'string' },
            rating: { type: 'number', minimum: 1, maximum: 5 },
            review: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        Message: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            conversationId: { type: 'string' },
            senderId: { type: 'string' },
            senderType: { type: 'string', enum: ['User', 'Provider'] },
            recipientId: { type: 'string' },
            recipientType: { type: 'string', enum: ['User', 'Provider'] },
            text: { type: 'string' },
            timestamp: { type: 'string', format: 'date-time' },
            readByRecipient: { type: 'boolean' }
          }
        },
        Notification: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            recipient: { type: 'string' },
            recipientModel: { type: 'string', enum: ['User', 'Provider'] },
            type: { 
              type: 'string', 
              enum: ['booking_created', 'booking_accepted', 'booking_declined', 'booking_cancelled', 'booking_in_progress', 'booking_completed', 'new_message', 'new_rating', 'payment_received', 'system_notification']
            },
            title: { type: 'string' },
            message: { type: 'string' },
            isRead: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'] // Path to the API docs
};

const specs = swaggerJsdoc(options);

module.exports = specs; 