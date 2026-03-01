const express = require('express');
const router = express.Router();
const { protectRoute, isUser, isProvider } = require('../middlewares/auth.middleware');
const notificationService = require('../services/notification.service');
const User = require('../models/user.model');
const Provider = require('../models/provider.model');

/**
 * @swagger
 * /api/notifications/fcm-token:
 *   put:
 *     summary: Update FCM token for user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fcmToken:
 *                 type: string
 *                 description: FCM token from device
 *     responses:
 *       200:
 *         description: FCM token updated successfully
 *       401:
 *         description: Unauthorized
 */
router.put('/fcm-token', protectRoute, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user.id;
    const userType = req.user.type;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    let success;
    if (userType === 'user') {
      success = await notificationService.updateUserFcmToken(userId, fcmToken);
    } else if (userType === 'provider') {
      success = await notificationService.updateProviderFcmToken(userId, fcmToken);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid user type'
      });
    }

    if (success) {
      res.json({
        success: true,
        message: 'FCM token updated successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to update FCM token'
      });
    }
  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @swagger
 * /api/notifications/fcm-token:
 *   delete:
 *     summary: Remove FCM token for user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: FCM token removed successfully
 *       401:
 *         description: Unauthorized
 */
router.delete('/fcm-token', protectRoute, async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type;

    let success;
    if (userType === 'user') {
      success = await notificationService.removeUserFcmToken(userId);
    } else if (userType === 'provider') {
      success = await notificationService.removeProviderFcmToken(userId);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid user type'
      });
    }

    if (success) {
      res.json({
        success: true,
        message: 'FCM token removed successfully'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to remove FCM token'
      });
    }
  } catch (error) {
    console.error('Error removing FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @swagger
 * /api/notifications/settings:
 *   get:
 *     summary: Get notification settings for user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notification settings retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     notificationSettings:
 *                       type: object
 *       401:
 *         description: Unauthorized
 */
router.get('/settings', protectRoute, async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type;

    let user;
    if (userType === 'user') {
      user = await User.findById(userId).select('notificationSettings');
    } else if (userType === 'provider') {
      user = await Provider.findById(userId).select('notificationSettings');
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid user type'
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        notificationSettings: user.notificationSettings || {
          bookingUpdates: true,
          chatMessages: true,
          ratings: true,
          promotions: true
        }
      }
    });
  } catch (error) {
    console.error('Error getting notification settings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @swagger
 * /api/notifications/settings:
 *   put:
 *     summary: Update notification settings for user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               notificationSettings:
 *                 type: object
 *                 properties:
 *                   bookingUpdates:
 *                     type: boolean
 *                   chatMessages:
 *                     type: boolean
 *                   ratings:
 *                     type: boolean
 *                   promotions:
 *                     type: boolean
 *     responses:
 *       200:
 *         description: Notification settings updated successfully
 *       401:
 *         description: Unauthorized
 */
router.put('/settings', protectRoute, async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type;
    const { notificationSettings } = req.body;

    if (!notificationSettings) {
      return res.status(400).json({
        success: false,
        message: 'Notification settings are required'
      });
    }

    // Validate notification settings
    const validSettings = {
      bookingUpdates: typeof notificationSettings.bookingUpdates === 'boolean' ? notificationSettings.bookingUpdates : true,
      chatMessages: typeof notificationSettings.chatMessages === 'boolean' ? notificationSettings.chatMessages : true,
      ratings: typeof notificationSettings.ratings === 'boolean' ? notificationSettings.ratings : true,
      promotions: typeof notificationSettings.promotions === 'boolean' ? notificationSettings.promotions : true
    };

    let user;
    if (userType === 'user') {
      user = await User.findByIdAndUpdate(
        userId,
        { notificationSettings: validSettings },
        { new: true }
      ).select('notificationSettings');
    } else if (userType === 'provider') {
      user = await Provider.findByIdAndUpdate(
        userId,
        { notificationSettings: validSettings },
        { new: true }
      ).select('notificationSettings');
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid user type'
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        notificationSettings: user.notificationSettings
      },
      message: 'Notification settings updated successfully'
    });
  } catch (error) {
    console.error('Error updating notification settings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

/**
 * @swagger
 * /api/notifications/test:
 *   post:
 *     summary: Send test notification to current user
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Test notification sent successfully
 *       401:
 *         description: Unauthorized
 */
router.post('/test', protectRoute, async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type;

    const testNotification = {
      title: 'Test Notification',
      body: 'This is a test notification from JO Service',
      type: 'test',
      data: {
        test: 'true',
        timestamp: Date.now().toString()
      }
    };

    let result;
    if (userType === 'user') {
      result = await notificationService.sendNotification(userId, testNotification);
    } else if (userType === 'provider') {
      result = await notificationService.sendNotificationToProvider(userId, testNotification);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid user type'
      });
    }

    if (result) {
      res.json({
        success: true,
        message: 'Test notification sent successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Failed to send test notification. Make sure you have a valid FCM token.'
      });
    }
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router; 