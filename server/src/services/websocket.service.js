const WebSocket = require('ws');
const url = require('url');
const { verifyToken } = require('../utils/jwt.utils'); // Assuming you have this
const Message = require('../models/message.model'); // Import Message model

// In-memory storage for connected clients { userId/providerId: WebSocket connection }
// IMPORTANT: This is simple but not scalable for production. Consider Redis or another solution.
const clients = new Map();

function initializeWebSocket(server) {
    const wss = new WebSocket.Server({ server });

    wss.on('connection', async (ws, req) => {
        
        const parameters = url.parse(req.url, true).query;
        const token = parameters.token;
        let authInfo = null;

        if (token) {
            try {
                authInfo = verifyToken(token);
            } catch (err) {
                console.error('WebSocket Auth Error: Exception during verifyToken:', err.message);
                ws.send(JSON.stringify({ type: 'error', message: 'Authentication error: ' + err.message }));
                ws.close(1008, 'Invalid token'); // 1008 = Policy Violation
                return;
            }
        } else {
            console.error('WebSocket Auth Error: No token provided in query parameters.');
        }

        if (!authInfo || !authInfo.id || !authInfo.type) {
            console.error(`WebSocket Auth Error: Missing token or invalid payload. AuthInfo: ${JSON.stringify(authInfo)}`);
            ws.send(JSON.stringify({ type: 'error', message: 'Authentication required or invalid token payload.' }));
            ws.close(1008, 'Authentication required');
            return;
        }

        const clientId = authInfo.id; // User or Provider ID from token
        const clientType = authInfo.type; // 'user' or 'provider' (lowercase from token)

        // 2. Store the authenticated client connection
        clients.set(clientId, ws);
        ws.clientId = clientId; // Attach ID to the ws object for easier lookup on close

        ws.send(JSON.stringify({ type: 'info', message: 'Welcome to the Chat Service!' }));

        // 3. Handle incoming messages
        ws.on('message', async (messageBuffer) => {
            let messageData;
            try {
                messageData = JSON.parse(messageBuffer.toString());

                // Basic validation
                if (!messageData.recipientId || !messageData.text) {
                    throw new Error('Invalid message format');
                }

                // Corrected recipientType determination
                // Assuming if sender is 'user', recipient is 'Provider', and vice-versa.
                // This might need to be more robust if users can message users, or providers message providers.
                let recipientType;
                if (clientType === 'user') {
                    recipientType = 'Provider';
                } else if (clientType === 'provider') {
                    recipientType = 'User';
                } else {
                    console.error('Unknown clientType for determining recipientType:', clientType);
                    ws.send(JSON.stringify({ type: 'error', message: 'Internal server error: Could not determine recipient type.' }));
                    return; // Stop processing if recipient type is unknown
                }

                const newMessage = new Message({
                    conversationId: Message.generateConversationId(clientId, messageData.recipientId),
                    senderId: clientId,
                    senderType: clientType === 'user' ? 'User' : 'Provider', // Map from token to capitalized for Model
                    recipientId: messageData.recipientId,
                    recipientType: recipientType, 
                    text: messageData.text,
                    // timestamp will default to Date.now in schema
                });
                
                // Save message to DB *before* sending to recipient for reliability
                try {
                    await newMessage.save();
                } catch (dbError) {
                    console.error('Failed to save message to DB:', dbError);
                    // Decide if we should still try to send or notify sender of DB error
                    ws.send(JSON.stringify({ type: 'error', message: 'Failed to store message.' }));
                    return; // Stop processing if DB save fails
                }

                // Prepare outgoing message for WebSocket (could be same as newMessage structure)
                const outgoingMessage = {
                    ...newMessage.toObject(), // Use saved message data
                    timestamp: newMessage.timestamp.toISOString() // Ensure consistent ISO string format
                };
                delete outgoingMessage._id; // Usually don't send DB ID over WS
                delete outgoingMessage.__v;
                delete outgoingMessage.updatedAt;
                delete outgoingMessage.createdAt;
                
                // 4. Route message to recipient if they are online
                const recipientWs = clients.get(messageData.recipientId);
                if (recipientWs && recipientWs.readyState === ws.OPEN) {
                    recipientWs.send(JSON.stringify({ type: 'message', data: outgoingMessage }));
                } else {
                    // Log current connected client IDs for debugging
                    // TODO: Handle offline messaging (e.g., store in DB, send push notification)
                    ws.send(JSON.stringify({ type: 'error', message: `User ${messageData.recipientId} is not online.` }));
                }

            } catch (error) {
                console.error('Failed to process message:', error);
                ws.send(JSON.stringify({ type: 'error', message: 'Failed to process message: ' + error.message }));
            }
        });

        // 5. Handle client disconnection
        ws.on('close', () => {
            if (ws.clientId) {
                clients.delete(ws.clientId);
            }
        });

        // 6. Handle errors
        ws.on('error', (error) => {
            console.error(`WebSocket Error for ID=${ws.clientId}:`, error);
            if (ws.clientId) {
                clients.delete(ws.clientId);
            }
        });
    });

}

module.exports = { initializeWebSocket }; 