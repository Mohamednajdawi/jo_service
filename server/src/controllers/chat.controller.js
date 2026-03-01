const Message = require('../models/message.model');
const mongoose = require('mongoose');

const ChatController = {

    // GET /api/chats/:otherUserId - Get message history with another user
    async getChatHistory(req, res) {
        const currentUserId = req.auth.id; // From protectRoute middleware
        const otherUserId = req.params.otherUserId;

        if (!mongoose.Types.ObjectId.isValid(otherUserId)) {
             return res.status(400).json({ message: 'Invalid user ID format for chat partner.' });
        }
        
        if (currentUserId === otherUserId) {
            return res.status(400).json({ message: 'Cannot fetch chat history with yourself.' });
        }

        try {
            const conversationId = Message.generateConversationId(currentUserId, otherUserId);

            const messages = await Message.find({ conversationId: conversationId })
                                        .sort({ timestamp: 1 }) // Sort by timestamp ascending
                                        .limit(100); // Limit history length for performance
            
            // Optional: Add sender/recipient details by populating if needed, but adds complexity
            // Requires senderType/recipientType to be set correctly in the schema/refs
            // await Message.find(...).populate('senderId', 'fullName profilePictureUrl')... 

            res.status(200).json(messages);

        } catch (error) {
            console.error(`Error fetching chat history between ${currentUserId} and ${otherUserId}:`, error);
            res.status(500).json({ message: 'Failed to fetch chat history', error: error.message });
        }
    },

    // GET /api/chats - Get all conversations for the current user
    async getConversations(req, res) {
        const currentUserId = req.auth.id; // From protectRoute middleware
        const currentUserType = req.auth.userType; // 'user' or 'provider'

        try {
            const Booking = require('../models/booking.model');

            // 1. Find all bookings where the current user is the provider or the user.
            // This is needed for both virtual conversations and for linking messages to booking photos.
            const userBookings = await Booking.find({
                $or: [{ user: currentUserId }, { provider: currentUserId }]
            }).populate('user', 'fullName profilePictureUrl').populate('provider', 'fullName businessName profilePictureUrl')
            .sort({ createdAt: -1 }); // Sort by newest first

            const conversationPartners = new Map();

            // Group bookings by conversation partner and aggregate all photos
            userBookings.forEach(booking => {
                // Defensive check to ensure both parties exist
                if (!booking.user || !booking.provider) {
                  return; // Skip bookings that are missing a user or provider
                }
                
                const isCurrentUserProvider = booking.provider && booking.provider._id.toString() === currentUserId;
                const partner = isCurrentUserProvider ? booking.user : booking.provider;
                const partnerId = partner._id.toString();
                
                if (partner && conversationPartners.has(partnerId)) {
                    // Partner already exists, aggregate photos from this booking
                    const existingConversation = conversationPartners.get(partnerId);
                    
                    // Add photos from this booking to the existing conversation
                    if (booking.photos && booking.photos.length > 0) {
                        existingConversation.allBookingPhotos.push(...booking.photos);
                    }
                    
                    // Add this booking to the bookings array
                    existingConversation.allBookings.push({
                        _id: booking._id,
                        photos: booking.photos || [],
                        createdAt: booking.createdAt,
                        status: booking.status
                    });
                    
                    // Update last message time if this booking is newer
                    if (booking.createdAt > existingConversation.lastMessageTime) {
                        existingConversation.lastMessageTime = booking.createdAt;
                    }
                } else if (partner) {
                    // New conversation partner
                    conversationPartners.set(partnerId, {
                        id: Message.generateConversationId(currentUserId, partnerId),
                        participantId: partnerId,
                        participantName: partner.fullName || partner.businessName || 'Unknown',
                        participantAvatar: partner.profilePictureUrl || null,
                        participantType: isCurrentUserProvider ? 'user' : 'provider',
                        lastMessage: 'Booking confirmed. Say hello!',
                        lastMessageTime: booking.createdAt,
                        lastMessageSenderId: '',
                        unreadCount: 0,
                        isOnline: false,
                        // Store ALL booking photos from ALL bookings with this partner
                        allBookingPhotos: booking.photos ? [...booking.photos] : [],
                        // Store ALL bookings with this partner for reference
                        allBookings: [{
                            _id: booking._id,
                            photos: booking.photos || [],
                            createdAt: booking.createdAt,
                            status: booking.status
                        }],
                        // Keep reference to the most recent booking for backward compatibility
                        booking: {
                            _id: booking._id,
                            photos: booking.photos || []
                        }
                    });
                }
            });

            // 2. Find all existing message conversations
            const messageConversations = await Message.aggregate([
                {
                    $match: {
                        $or: [
                            { senderId: new mongoose.Types.ObjectId(currentUserId) },
                            { recipientId: new mongoose.Types.ObjectId(currentUserId) }
                        ]
                    }
                },
                {
                    $sort: { timestamp: -1 }
                },
                {
                    $group: {
                        _id: '$conversationId',
                        lastMessage: { $first: '$$ROOT' },
                        unreadCount: {
                            $sum: {
                                $cond: [
                                    {
                                        $and: [
                                            { $eq: ['$recipientId', new mongoose.Types.ObjectId(currentUserId)] },
                                            { $eq: ['$readByRecipient', false] }
                                        ]
                                    },
                                    1,
                                    0
                                ]
                            }
                        }
                    }
                },
                {
                    $sort: { 'lastMessage.timestamp': -1 }
                }
            ]);

            // Now populate the participant details
            const User = require('../models/user.model');
            const Provider = require('../models/provider.model');

            const enrichedConversations = await Promise.all(
                messageConversations.map(async (conv) => {
                    const lastMessage = conv.lastMessage;
                    
                    // Determine who the other participant is
                    const isCurrentUserSender = lastMessage.senderId.toString() === currentUserId;
                    const otherUserId = isCurrentUserSender ? lastMessage.recipientId : lastMessage.senderId;
                    const otherUserType = isCurrentUserSender ? lastMessage.recipientType : lastMessage.senderType;
                    
                    // Fetch the other participant's details
                    let participant;
                    if (otherUserType === 'User') {
                        participant = await User.findById(otherUserId).select('fullName profilePictureUrl');
                    } else {
                        participant = await Provider.findById(otherUserId).select('fullName businessName profilePictureUrl');
                    }

                    // Skip this conversation if participant not found
                    if (!participant) {
                        return null;
                    }

                    // Find ALL bookings associated with this conversation partner
                    const partnerBookings = userBookings.filter(b =>
                        (b.user?._id.toString() === currentUserId && b.provider?._id.toString() === participant._id.toString()) ||
                        (b.provider?._id.toString() === currentUserId && b.user?._id.toString() === participant._id.toString())
                    );

                    // Aggregate all photos from all bookings with this partner
                    const allBookingPhotos = [];
                    const allBookings = [];
                    
                    partnerBookings.forEach(booking => {
                        if (booking.photos && booking.photos.length > 0) {
                            allBookingPhotos.push(...booking.photos);
                        }
                        allBookings.push({
                            _id: booking._id,
                            photos: booking.photos || [],
                            createdAt: booking.createdAt,
                            status: booking.status
                        });
                    });

                    // Get the most recent booking for backward compatibility
                    const mostRecentBooking = partnerBookings.length > 0 ? partnerBookings[0] : null;

                    return {
                        id: conv._id.toString(),
                        participantId: participant._id.toString(),
                        participantName: participant.fullName || participant.businessName || 'Unknown',
                        participantAvatar: participant.profilePictureUrl,
                        participantType: otherUserType.toLowerCase(),
                        lastMessage: lastMessage.text,
                        lastMessageTime: lastMessage.timestamp,
                        lastMessageSenderId: lastMessage.senderId.toString(),
                        // Include ALL booking photos from ALL bookings with this partner
                        allBookingPhotos: allBookingPhotos,
                        allBookings: allBookings,
                        // Keep backward compatibility
                        booking: mostRecentBooking ? { 
                            _id: mostRecentBooking._id.toString(), 
                            photos: mostRecentBooking.photos || [] 
                        } : null,
                        unreadCount: conv.unreadCount,
                        isOnline: false // TODO: Implement online status if needed
                    };
                })
            ).then(results => results.filter(conv => conv !== null)); // Filter out null values

            // Merge message conversations with booking conversations
            enrichedConversations.forEach(conv => {
                if (!conversationPartners.has(conv.participantId)) {
                    conversationPartners.set(conv.participantId, conv);
                } else {
                    // If a message conversation exists, it's more up-to-date than the booking placeholder
                    const existing = conversationPartners.get(conv.participantId);
                    // The message-based 'conv' is more up-to-date, but we need the booking data from 'existing'.
                    // So, we update 'existing' with the new message info, preserving the booking data.
                    existing.lastMessage = conv.lastMessage;
                    existing.lastMessageTime = conv.lastMessageTime;
                    existing.lastMessageSenderId = conv.lastMessageSenderId;
                    existing.unreadCount = conv.unreadCount;
                    // Merge booking photos - use the aggregated photos from message conversation if available
                    if (conv.allBookingPhotos && conv.allBookingPhotos.length > 0) {
                        existing.allBookingPhotos = conv.allBookingPhotos;
                        existing.allBookings = conv.allBookings;
                    }
                }
            });

            const finalConversations = Array.from(conversationPartners.values());
            
            // Transform the conversations to include all booking photos in the main booking field for frontend compatibility
            const transformedConversations = finalConversations.map(conv => ({
                ...conv,
                // Update the booking field to include ALL photos from ALL bookings
                booking: {
                    _id: conv.booking?._id || '',
                    photos: conv.allBookingPhotos || []
                }
            }));
            
            transformedConversations.sort((a, b) => new Date(b.lastMessageTime) - new Date(a.lastMessageTime));

            transformedConversations.forEach(conv => {
            });

            res.status(200).json({ conversations: transformedConversations });

        } catch (error) {
            console.error(`Error fetching conversations for user ${currentUserId}:`, error);
            res.status(500).json({ message: 'Failed to fetch conversations', error: error.message });
        }
    },

    // PATCH /api/chats/:conversationId/read - Mark all messages in a conversation as read
    async markMessagesAsRead(req, res) {
        const currentUserId = req.auth.id;
        const conversationId = req.params.conversationId;

        try {
            // Update all messages in this conversation where the current user is the recipient
            const result = await Message.updateMany(
                {
                    conversationId: conversationId,
                    recipientId: currentUserId,
                    isRead: false
                },
                {
                    $set: { isRead: true, readAt: new Date() }
                }
            );


            res.status(200).json({
                message: 'Messages marked as read',
                updatedCount: result.modifiedCount
            });

        } catch (error) {
            console.error(`Error marking messages as read for conversation ${conversationId}:`, error);
            res.status(500).json({ message: 'Failed to mark messages as read', error: error.message });
        }
    },

    // DELETE /api/chats/messages/:messageId - Delete a specific message
    async deleteMessage(req, res) {
        const currentUserId = req.auth.id;
        const messageId = req.params.messageId;

        if (!mongoose.Types.ObjectId.isValid(messageId)) {
            return res.status(400).json({ message: 'Invalid message ID format.' });
        }

        try {
            // Find the message
            const message = await Message.findById(messageId);
            
            if (!message) {
                return res.status(404).json({ message: 'Message not found.' });
            }

            // Check if the current user is the sender of this message
            if (message.senderId.toString() !== currentUserId) {
                return res.status(403).json({ message: 'You can only delete your own messages.' });
            }

            // If the message has images, we could optionally delete the image files from disk
            // For now, we'll just delete the message record
            if (message.images && message.images.length > 0) {
                // TODO: Optionally delete image files from disk
                // const fs = require('fs');
                // const path = require('path');
                // message.images.forEach(imageUrl => {
                //     const imagePath = path.join(__dirname, '../../public', imageUrl);
                //     if (fs.existsSync(imagePath)) {
                //         fs.unlinkSync(imagePath);
                //     }
                // });
            }

            // Delete the message
            await Message.findByIdAndDelete(messageId);


            res.status(200).json({ 
                message: 'Message deleted successfully',
                deletedMessageId: messageId
            });

        } catch (error) {
            console.error(`Error deleting message ${messageId}:`, error);
            res.status(500).json({ message: 'Failed to delete message', error: error.message });
        }
    },

    // DELETE /api/chats/:conversationId - Delete a conversation (all messages between two users)
    async deleteConversation(req, res) {
        const currentUserId = req.auth.id;
        const conversationId = req.params.conversationId;

        try {
            // Verify the current user is part of this conversation
            const messagesInConversation = await Message.find({
                conversationId: conversationId,
                $or: [
                    { senderId: currentUserId },
                    { recipientId: currentUserId }
                ]
            }).limit(1);

            if (messagesInConversation.length === 0) {
                return res.status(404).json({ message: 'Conversation not found or you are not part of this conversation' });
            }

            // Delete all messages in this conversation
            const result = await Message.deleteMany({
                conversationId: conversationId
            });


            res.status(200).json({
                message: 'Conversation deleted successfully',
                deletedCount: result.deletedCount
            });

        } catch (error) {
            console.error(`Error deleting conversation ${conversationId}:`, error);
            res.status(500).json({ message: 'Failed to delete conversation', error: error.message });
        }
    },

    // GET /api/chats/:conversationId/unread-count - Get unread message count for a specific conversation
    async getUnreadCount(req, res) {
        const currentUserId = req.auth.id;
        const conversationId = req.params.conversationId;

        try {
            const unreadCount = await Message.countDocuments({
                conversationId: conversationId,
                recipientId: currentUserId,
                isRead: false
            });

            res.status(200).json({ unreadCount });

        } catch (error) {
            console.error(`Error getting unread count for conversation ${conversationId}:`, error);
            res.status(500).json({ message: 'Failed to get unread count', error: error.message });
        }
    },

    // POST /api/chats/:recipientId/images - Send image message
    async sendImageMessage(req, res) {
        const currentUserId = req.auth.id;
        const currentUserType = req.auth.userType;
        const recipientId = req.params.recipientId;
        const { text, recipientType } = req.body;
        const uploadedFiles = req.files || [];

        console.log('sendImageMessage params:', {
            currentUserId,
            currentUserType,
            recipientId,
            recipientType,
            text,
            fileCount: uploadedFiles.length
        });

        if (!recipientId) {
            return res.status(400).json({ message: 'Recipient ID is required' });
        }

        if (!uploadedFiles || uploadedFiles.length === 0) {
            return res.status(400).json({ message: 'At least one image is required' });
        }

        try {
            // Process uploaded images
            const imageUrls = [];
            uploadedFiles.forEach(file => {
                const imageUrl = `/uploads/${file.filename}`;
                imageUrls.push(imageUrl);
            });

            // Generate conversation ID
            const conversationId = Message.generateConversationId(currentUserId, recipientId);

            // Create the message
            const newMessage = new Message({
                conversationId,
                senderId: currentUserId,
                senderType: currentUserType === 'user' ? 'User' : 'Provider',
                recipientId,
                recipientType: recipientType ? (recipientType.toLowerCase() === 'provider' ? 'Provider' : 'User') : (currentUserType === 'user' ? 'Provider' : 'User'),
                messageType: 'image',
                text: text || '',
                images: imageUrls,
                timestamp: new Date()
            });

            const savedMessage = await newMessage.save();

            // TODO: Send real-time notification via WebSocket if implemented

            res.status(201).json({
                message: 'Image message sent successfully',
                messageId: savedMessage._id,
                images: imageUrls
            });

        } catch (error) {
            console.error('Error sending image message:', error);
            res.status(500).json({ message: 'Failed to send image message', error: error.message });
        }
    }
};

module.exports = ChatController; 