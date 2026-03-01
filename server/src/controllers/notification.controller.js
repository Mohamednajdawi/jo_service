const NotificationService = require('../services/notification.service');

const NotificationController = {
    // GET /api/notifications - Get notifications for the logged-in user
    async getNotifications(req, res) {
        try {
            const userId = req.auth.id;
            const userType = req.auth.type === 'user' ? 'User' : 'Provider';
            const { page = 1, limit = 20, unreadOnly = false } = req.query;
            
            
            const result = await NotificationService.getUserNotifications(
                userId,
                userType,
                {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    unreadOnly: unreadOnly === 'true'
                }
            );
            
            res.status(200).json(result);
        } catch (error) {
            console.error('Error getting notifications:', error);
            res.status(500).json({ message: 'Failed to get notifications', error: error.message });
        }
    },
    
    // PATCH /api/notifications/:id/read - Mark a notification as read
    async markAsRead(req, res) {
        try {
            const notificationId = req.params.id;
            const userId = req.auth.id;
            
            
            const updatedNotification = await NotificationService.markAsRead(notificationId);
            
            if (!updatedNotification) {
                return res.status(404).json({ message: 'Notification not found' });
            }
            
            // Verify that the notification belongs to the user
            if (updatedNotification.recipient.toString() !== userId) {
                return res.status(403).json({ message: 'You do not have permission to update this notification' });
            }
            
            res.status(200).json(updatedNotification);
        } catch (error) {
            console.error('Error marking notification as read:', error);
            res.status(500).json({ message: 'Failed to mark notification as read', error: error.message });
        }
    },
    
    // PATCH /api/notifications/read-all - Mark all notifications as read
    async markAllAsRead(req, res) {
        try {
            const userId = req.auth.id;
            const userType = req.auth.type === 'user' ? 'User' : 'Provider';
            
            
            const result = await NotificationService.markAllAsRead(userId, userType);
            
            res.status(200).json({
                message: 'All notifications marked as read',
                count: result.modifiedCount
            });
        } catch (error) {
            console.error('Error marking all notifications as read:', error);
            res.status(500).json({ message: 'Failed to mark all notifications as read', error: error.message });
        }
    },
    
    // GET /api/notifications/unread-count - Get the count of unread notifications
    async getUnreadCount(req, res) {
        try {
            const userId = req.auth.id;
            const userType = req.auth.type === 'user' ? 'User' : 'Provider';
            
            
            const result = await NotificationService.getUserNotifications(
                userId,
                userType,
                { unreadOnly: true, limit: 1 }
            );
            
            res.status(200).json({ unreadCount: result.unreadCount });
        } catch (error) {
            console.error('Error getting unread notification count:', error);
            res.status(500).json({ message: 'Failed to get unread notification count', error: error.message });
        }
    }
};

module.exports = NotificationController; 