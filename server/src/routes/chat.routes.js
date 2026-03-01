const express = require('express');
const ChatController = require('../controllers/chat.controller');
const { protectRoute } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');

const router = express.Router();

// GET /api/chats - Get all conversations for the current user
// Requires authentication
router.get('/', protectRoute, ChatController.getConversations);

// GET /api/chats/:otherUserId - Get message history with another user
// Requires authentication
router.get('/:otherUserId', protectRoute, ChatController.getChatHistory);

// PATCH /api/chats/:conversationId/read - Mark messages as read
router.patch('/:conversationId/read', protectRoute, ChatController.markMessagesAsRead);

// DELETE /api/chats/messages/:messageId - Delete a specific message
router.delete('/messages/:messageId', protectRoute, ChatController.deleteMessage);

// DELETE /api/chats/:conversationId - Delete conversation
router.delete('/:conversationId', protectRoute, ChatController.deleteConversation);

// GET /api/chats/:conversationId/unread-count - Get unread count
router.get('/:conversationId/unread-count', protectRoute, ChatController.getUnreadCount);

// POST /api/chats/:recipientId/images - Send image message
router.post('/:recipientId/images', protectRoute, upload.array('images', 5), ChatController.sendImageMessage);

module.exports = router; 