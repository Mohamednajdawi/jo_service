const admin = require('firebase-admin');
const User = require('../models/user.model');
const Provider = require('../models/provider.model');

class NotificationService {
  constructor() {
    // Initialize Firebase Admin SDK
    // Note: In production, you should use service account key file
    // For development, you can use application default credentials
    try {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID || 'jo-service-marketplace'
      });
    } catch (error) {
      // App already initialized
      console.log('Firebase Admin already initialized');
    }
  }

  /**
   * Send notification to a specific user
   * @param {string} userId - User ID
   * @param {Object} notification - Notification object
   * @param {string} notification.title - Notification title
   * @param {string} notification.body - Notification body
   * @param {string} notification.type - Notification type
   * @param {Object} notification.data - Additional data
   */
  async sendNotification(userId, notification) {
    try {
      const user = await User.findById(userId);
      if (!user || !user.fcmToken) {
        console.log(`User ${userId} not found or no FCM token`);
        return null;
      }

      // Check notification settings
      if (!this.shouldSendNotification(user, notification.type)) {
        console.log(`Notification ${notification.type} disabled for user ${userId}`);
        return null;
      }

      const message = {
        token: user.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: {
          type: notification.type,
          ...notification.data
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'jo_service_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log(`Notification sent to user ${userId}:`, response);
      return response;
        } catch (error) {
      console.error('Error sending notification to user:', error);
      return null;
        }
    }

    /**
   * Send notification to a specific provider
   * @param {string} providerId - Provider ID
   * @param {Object} notification - Notification object
   */
  async sendNotificationToProvider(providerId, notification) {
    try {
      const provider = await Provider.findById(providerId);
      if (!provider || !provider.fcmToken) {
        console.log(`Provider ${providerId} not found or no FCM token`);
        return null;
      }

      // Check notification settings
      if (!this.shouldSendNotification(provider, notification.type)) {
        console.log(`Notification ${notification.type} disabled for provider ${providerId}`);
        return null;
      }

      const message = {
        token: provider.fcmToken,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: {
          type: notification.type,
          ...notification.data
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'jo_service_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log(`Notification sent to provider ${providerId}:`, response);
      return response;
    } catch (error) {
      console.error('Error sending notification to provider:', error);
      return null;
    }
  }

  /**
   * Send notification to multiple users
   * @param {Array} userIds - Array of user IDs
   * @param {Object} notification - Notification object
   */
  async sendNotificationToUsers(userIds, notification) {
    const results = [];
    for (const userId of userIds) {
      const result = await this.sendNotification(userId, notification);
      results.push({ userId, result });
    }
    return results;
  }

  /**
   * Send notification to multiple providers
   * @param {Array} providerIds - Array of provider IDs
   * @param {Object} notification - Notification object
   */
  async sendNotificationToProviders(providerIds, notification) {
    const results = [];
    for (const providerId of providerIds) {
      const result = await this.sendNotificationToProvider(providerId, notification);
      results.push({ providerId, result });
    }
    return results;
  }

  /**
   * Send notification to topic subscribers
   * @param {string} topic - Topic name
   * @param {Object} notification - Notification object
   */
  async sendNotificationToTopic(topic, notification) {
    try {
      const message = {
        topic: topic,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: {
          type: notification.type,
          ...notification.data
        }
      };

      const response = await admin.messaging().send(message);
      console.log(`Notification sent to topic ${topic}:`, response);
      return response;
    } catch (error) {
      console.error('Error sending notification to topic:', error);
      return null;
    }
  }

  /**
   * Subscribe user to topic
   * @param {string} fcmToken - FCM token
   * @param {string} topic - Topic name
   */
  async subscribeToTopic(fcmToken, topic) {
    try {
      const response = await admin.messaging().subscribeToTopic([fcmToken], topic);
      console.log(`Subscribed to topic ${topic}:`, response);
      return response;
    } catch (error) {
      console.error('Error subscribing to topic:', error);
      return null;
    }
  }

  /**
   * Unsubscribe user from topic
   * @param {string} fcmToken - FCM token
   * @param {string} topic - Topic name
   */
  async unsubscribeFromTopic(fcmToken, topic) {
    try {
      const response = await admin.messaging().unsubscribeFromTopic([fcmToken], topic);
      console.log(`Unsubscribed from topic ${topic}:`, response);
      return response;
        } catch (error) {
      console.error('Error unsubscribing from topic:', error);
      return null;
        }
    }

    /**
   * Check if notification should be sent based on user settings
   * @param {Object} user - User or provider object
   * @param {string} notificationType - Type of notification
   */
  shouldSendNotification(user, notificationType) {
    if (!user.notificationSettings) {
      return true; // Default to true if no settings
    }

    switch (notificationType) {
      case 'booking_created':
      case 'booking_accepted':
      case 'booking_declined':
      case 'booking_started':
      case 'booking_completed':
      case 'booking_cancelled':
        return user.notificationSettings.bookingUpdates;
      
      case 'chat_message':
      case 'new_message':
        return user.notificationSettings.chatMessages;
      
      case 'new_rating':
      case 'rating_received':
        return user.notificationSettings.ratings;
      
      case 'promotion':
      case 'special_offer':
        return user.notificationSettings.promotions;
      
      default:
        return true;
    }
  }

  /**
   * Update FCM token for user
   * @param {string} userId - User ID
   * @param {string} fcmToken - FCM token
   */
  async updateUserFcmToken(userId, fcmToken) {
    try {
      await User.findByIdAndUpdate(userId, { fcmToken });
      console.log(`FCM token updated for user ${userId}`);
      return true;
        } catch (error) {
      console.error('Error updating user FCM token:', error);
      return false;
        }
    }

    /**
   * Update FCM token for provider
   * @param {string} providerId - Provider ID
   * @param {string} fcmToken - FCM token
   */
  async updateProviderFcmToken(providerId, fcmToken) {
    try {
      await Provider.findByIdAndUpdate(providerId, { fcmToken });
      console.log(`FCM token updated for provider ${providerId}`);
      return true;
        } catch (error) {
      console.error('Error updating provider FCM token:', error);
      return false;
        }
    }

    /**
   * Remove FCM token for user
   * @param {string} userId - User ID
   */
  async removeUserFcmToken(userId) {
    try {
      await User.findByIdAndUpdate(userId, { fcmToken: null });
      console.log(`FCM token removed for user ${userId}`);
      return true;
    } catch (error) {
      console.error('Error removing user FCM token:', error);
      return false;
    }
  }

  /**
   * Remove FCM token for provider
   * @param {string} providerId - Provider ID
   */
  async removeProviderFcmToken(providerId) {
    try {
      await Provider.findByIdAndUpdate(providerId, { fcmToken: null });
      console.log(`FCM token removed for provider ${providerId}`);
      return true;
        } catch (error) {
      console.error('Error removing provider FCM token:', error);
      return false;
        }
    }
}

module.exports = new NotificationService(); 