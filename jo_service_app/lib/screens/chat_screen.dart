import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/chat_message.model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/conversation_service.dart';
import '../models/booking_model.dart';
import '../models/chat_conversation.dart';
import '../widgets/full_screen_image_viewer.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({required this.conversation, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final BookingService _bookingService = BookingService();
  late final ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<ChatMessage> _messages = [];
  List<Booking> _relatedBookings = [];
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;
  bool _isLoading = true;
  late final AuthService _authService;
  ChatConversation? _updatedConversation;
  Timer? _refreshTimer;
  bool _isTyping = false;
  late AnimationController _animationController;

  // iOS-style colors
  static const Color _iMessageBlue = Color(0xFF007AFF);
  static const Color _messageGray = Color(0xFFE5E5EA);
  static const Color _textGray = Color(0xFF8E8E93);
  static const Color _backgroundGray = Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = Provider.of<AuthService>(context, listen: false);
    _chatService = ChatService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Use conversation data directly instead of fetching
    _initializeChat();
    
    // Start periodic refresh for booking photos every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshBookingPhotos();
    });
    
    // Initial refresh after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _refreshBookingPhotos();
    });

    // Listen to text changes for typing indicator (future feature)
    _messageController.addListener(() {
      final isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
      if (isCurrentlyTyping != _isTyping) {
        setState(() {
          _isTyping = isCurrentlyTyping;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _messageSubscription?.cancel();
    _chatService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back into focus, refresh booking photos
      _refreshBookingPhotos();
    }
  }

  // Refresh booking photos from backend
  Future<void> _refreshBookingPhotos() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;
      
      final conversationService = ConversationService();
      final conversations = await conversationService.getConversations(token: token);
      
      // Find the current conversation in the updated list
      final updatedConversation = conversations.firstWhere(
        (conv) => conv.participantId == widget.conversation.participantId,
        orElse: () => widget.conversation,
      );
      
      // Get current photos for comparison
      final currentPhotos = _updatedConversation?.bookingPhotos ?? widget.conversation.bookingPhotos;
      final newPhotos = updatedConversation.bookingPhotos;
      
      // Check if photos have changed (count or content)
      bool photosChanged = false;
      if (currentPhotos.length != newPhotos.length) {
        photosChanged = true;
      } else {
        // Check if any photo URLs are different
        for (int i = 0; i < currentPhotos.length; i++) {
          if (currentPhotos[i] != newPhotos[i]) {
            photosChanged = true;
            break;
          }
        }
      }
      
      if (photosChanged) {
        setState(() {
          _updatedConversation = updatedConversation;
        });
      } else {
      }
    } catch (e) {
    }
  }

  void _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    final token = await _authService.getToken();
    final currentUserId = await _authService.getUserId();

    if (token == null ||
        token.isEmpty ||
        currentUserId == null ||
        currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required.')));
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Refresh conversation data to get the latest booking photos
    try {
      final conversationService = ConversationService();
      final conversations = await conversationService.getConversations(token: token);
      
      // Find the current conversation in the updated list
      final updatedConversation = conversations.firstWhere(
        (conv) => conv.participantId == widget.conversation.participantId,
        orElse: () => widget.conversation,
      );
      
      // Always update the conversation with the latest data including booking photos
      setState(() {
        // Always store the updated conversation data to preserve booking photos
        _updatedConversation = updatedConversation;
      });
    } catch (e) {
    }

    // 2. Load Chat History
    List<ChatMessage> history = [];
    try {
      history = await _apiService.fetchChatHistory(
          widget.conversation.participantId, token, currentUserId);
      for (var msg in history) {
        if (msg.hasImages) {
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load chat history: $e')));
      }
      // Continue to connect even if history fails?
    }

    // 3. Connect to WebSocket and listen for new messages
    bool connected = await _chatService.connect(widget.conversation.participantId);

    setState(() {
      _messages = history; // Initialize with history
      _isConnected = connected;
      _isLoading = false;
      _scrollToBottom(); // Scroll after loading history
    });

    if (connected) {
      _messageSubscription = _chatService.messages?.listen((newMessage) {
        setState(() {
          // Check if this message belongs to this conversation
          bool isRelevantMessage = (newMessage.senderId == currentUserId && newMessage.recipientId == widget.conversation.participantId) ||
                                  (newMessage.senderId == widget.conversation.participantId && newMessage.recipientId == currentUserId);
          
          if (isRelevantMessage) {
            // Avoid adding duplicates if message was already loaded via history
            bool isDuplicate = _messages.any((m) =>
                m.senderId == newMessage.senderId &&
                m.recipientId == newMessage.recipientId &&
                m.timestamp == newMessage.timestamp &&
                m.text == newMessage.text);
            
            if (!isDuplicate) {
              _messages.add(newMessage);
              _messages.sort(
                  (a, b) => a.timestamp.compareTo(b.timestamp)); // Ensure order
            } else {
            }
          } else {
          }
        });
        _scrollToBottom();
      }, onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Chat error: $error')));
        }
        if (mounted)
          setState(() {
            _isConnected = false;
          });
      }, onDone: () {
        if (mounted)
          setState(() {
            _isConnected = false;
          });
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to connect to chat service.')));
      }
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isNotEmpty && _isConnected) {
      
      // Haptic feedback for sending message
      HapticFeedback.lightImpact();
      
      // Get current user ID and type for creating the optimistic message
      final currentUserId = await _authService.getUserId();
      final currentUserType = await _authService.getUserType();
      
      if (currentUserId != null && currentUserType != null) {
        // Create optimistic message and add it immediately to the UI
        final optimisticMessage = ChatMessage(
          senderId: currentUserId,
          recipientId: widget.conversation.participantId,
          text: messageText,
          timestamp: DateTime.now(),
          senderType: currentUserType,
          isMe: true,
        );
        
        setState(() {
          _messages.add(optimisticMessage);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        
        _scrollToBottom(); // Optimistically scroll
      }
      
      // Clear input and trigger animation
      _messageController.clear();
      setState(() {}); // Update send button animation
      
      // Send message via WebSocket
      _chatService.sendMessage(widget.conversation.participantId, messageText);
    } else {
      if (!_isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Not connected to chat service'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Helper to scroll to the bottom of the list with iOS-style animation
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic, // iOS-style animation curve
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      appBar: _buildModernAppBar(),
      body: Column(
        children: <Widget>[
          _buildBookingPhotos(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_iMessageBlue),
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: _getItemCount(),
                        itemBuilder: (BuildContext context, int index) {
                          return _buildChatItem(index);
                        },
                      ),
          ),
          _buildModernMessageInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF007AFF), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.conversation.participantId}',
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: widget.conversation.participantAvatar != null && 
                     widget.conversation.participantAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        '${ConversationService.baseImageUrl}/${widget.conversation.participantAvatar}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback();
                        },
                      ),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.participantName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Online', // You can implement real online status later
                  style: TextStyle(
                    color: _textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: Color(0xFF007AFF)),
          onPressed: () {
            // Future: Video call functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone, color: Color(0xFF007AFF)),
          onPressed: () {
            // Future: Voice call functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.conversation.participantName.isNotEmpty 
              ? widget.conversation.participantName[0].toUpperCase() 
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _iMessageBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: _iMessageBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 16,
              color: _textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPhotos() {
    // Always prioritize _updatedConversation, and ensure we have the latest data
    final conversation = _updatedConversation ?? widget.conversation;
    
    if (conversation.bookingPhotos.isEmpty) {
      return const SizedBox.shrink(); // No photos, show nothing
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _iMessageBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      size: 16,
                      color: _iMessageBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Booking Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _iMessageBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${conversation.bookingPhotos.length} photo${conversation.bookingPhotos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: _textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: conversation.bookingPhotos.length,
              itemBuilder: (context, index) {
                final photoUrl = conversation.bookingPhotos[index];
                final fullUrl = photoUrl.startsWith('http') 
                    ? photoUrl 
                    : '${ConversationService.baseImageUrl}${photoUrl.startsWith('/') ? photoUrl : '/$photoUrl'}';
                

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < conversation.bookingPhotos.length - 1 ? 8.0 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _openFullScreenImage(fullUrl),
                    child: Hero(
                      tag: 'booking_photo_$index',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  color: _backgroundGray,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(_iMessageBlue),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: _backgroundGray,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_rounded,
                                      color: _textGray,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Error',
                                      style: TextStyle(
                                        color: _textGray,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getItemCount() {
    // Count booking photos + regular messages
    int photoCount = 0;
    for (var booking in _relatedBookings) {
      if (booking.photos != null && booking.photos!.isNotEmpty) {
        photoCount += booking.photos!.length;
      }
    }
    return photoCount + _messages.length;
  }

  Widget _buildChatItem(int index) {
    // First, show all booking photos
    int photoIndex = 0;
    for (var booking in _relatedBookings) {
      if (booking.photos != null && booking.photos!.isNotEmpty) {
        for (var photo in booking.photos!) {
          if (photoIndex == index) {
            return _buildBookingPhotoItem(booking, photo);
          }
          photoIndex++;
        }
      }
    }
    
    // Then show regular messages
    final messageIndex = index - photoIndex;
    if (messageIndex >= 0 && messageIndex < _messages.length) {
      return _buildMessageBubble(_messages[messageIndex]);
    }
    
    return Container(); // Fallback
  }

  Widget _buildBookingPhotoItem(Booking booking, String photoUrl) {
      final baseUrl = ConversationService.baseImageUrl;
    // Ensure proper URL construction for uploaded images
    String fullPhotoUrl;
    if (photoUrl.startsWith('http')) {
      fullPhotoUrl = photoUrl;
    } else if (photoUrl.startsWith('/uploads/')) {
      fullPhotoUrl = '$baseUrl$photoUrl';
    } else {
      fullPhotoUrl = '$baseUrl/uploads/$photoUrl';
    }
    
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Booking Photo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              fullPhotoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (booking.userNotes != null && booking.userNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${booking.userNotes}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Booking: ${booking.serviceDateTime.day}/${booking.serviceDateTime.month}/${booking.serviceDateTime.year}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildMessageBubble(ChatMessage message) {
    final bool isMe = message.isMe;
    final bool showTail = true; // You can implement logic to hide tail for consecutive messages
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar for received messages
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: widget.conversation.participantAvatar != null && 
                     widget.conversation.participantAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        '${ConversationService.baseImageUrl}/${widget.conversation.participantAvatar}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildSmallAvatarFallback();
                        },
                      ),
                    )
                  : _buildSmallAvatarFallback(),
            ),
          ],
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                // Haptic feedback for long press
                HapticFeedback.mediumImpact();
                if (isMe && message.id != null) {
                  _showDeleteMessageDialog(message);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  minWidth: 44,
                ),
                margin: EdgeInsets.only(
                  left: isMe ? 48 : 0,
                  right: isMe ? 0 : 48,
                  bottom: 4,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message bubble container
                    Container(
                      decoration: BoxDecoration(
                        color: isMe ? _iMessageBlue : _messageGray,
                        borderRadius: _getBubbleBorderRadius(isMe, showTail),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildMessageContent(message, isMe),
                    ),
                    
                    // Timestamp
                    if (message.text.isNotEmpty || message.hasImages)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                        child: Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: _textGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMe) ...[
            // Spacing for sent messages
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallAvatarFallback() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.conversation.participantName.isNotEmpty 
              ? widget.conversation.participantName[0].toUpperCase() 
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  BorderRadius _getBubbleBorderRadius(bool isMe, bool showTail) {
    const double radius = 20.0;
    const double tailRadius = 4.0;
    
    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        bottomRight: Radius.circular(showTail ? tailRadius : radius),
      );
    } else {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: Radius.circular(showTail ? tailRadius : radius),
        bottomRight: const Radius.circular(radius),
      );
    }
  }

  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking indicator
          if (message.isBookingMessage) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withOpacity(0.2) : _iMessageBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: isMe ? Colors.white : _iMessageBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Booking Photos',
                    style: TextStyle(
                      color: isMe ? Colors.white : _iMessageBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Images
          if (message.hasImages) ...[
            ...message.imageUrls!.map((imageUrl) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _openFullScreenImage(_getFullImageUrl(imageUrl)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 200,
                    ),
                    child: Image.network(
                      _getFullImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_iMessageBlue),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.grey[500], size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )).toList(),
          ],
          
          // Text message
          if (message.text.isNotEmpty)
            SelectableText(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      // Today - show time only
      final hour = timestamp.hour == 0 ? 12 : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
  
  // Helper method to construct full image URL
  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else if (imageUrl.startsWith('/')) {
      return '${ConversationService.baseImageUrl}$imageUrl';
    } else {
      return '${ConversationService.baseImageUrl}/$imageUrl';
    }
  }

  // Open image in full-screen viewer
  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  // Show delete message confirmation dialog with iOS-style design
  void _showDeleteMessageDialog(ChatMessage message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Delete Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message.hasImages 
              ? 'Are you sure you want to delete this image message? This action cannot be undone.'
              : 'Are you sure you want to delete this message? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: _textGray,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _iMessageBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(message);
              },
            ),
          ],
        );
      },
    );
  }

  // Delete a message
  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete this message')),
      );
      return;
    }

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Call API to delete message
      await _apiService.deleteMessage(message.id!, token);

      // Remove message from local list
      setState(() {
        _messages.removeWhere((msg) => msg.id == message.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: $e')),
      );
    }
  }

  // Pick and send image
  Future<void> _pickAndSendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show options for camera or gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      // Send the image
      await _sendImageMessage(File(image.path));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // Send image message to backend
  Future<void> _sendImageMessage(File imageFile) async {
    try {
      final token = await _authService.getToken();
      final currentUserId = await _authService.getUserId();
      
      if (token == null || currentUserId == null) {
        throw Exception('Authentication required');
      }

      final baseUrl = ConversationService.getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/chats/${widget.conversation.participantId}/images');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['recipientType'] = widget.conversation.participantType;
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
        ),
      );

      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        
        // Create optimistic message for immediate UI update
        final optimisticMessage = ChatMessage(
          senderId: currentUserId,
          recipientId: widget.conversation.participantId,
          text: '',
          timestamp: DateTime.now(),
          senderType: widget.conversation.participantType == 'user' ? 'provider' : 'user',
          isMe: true,
          messageType: 'image',
          imageUrls: [imageFile.path], // Use local path temporarily
        );
        
        setState(() {
          _messages.add(optimisticMessage);
        });
        
        _scrollToBottom();
        
      } else {
        throw Exception('Failed to send image: ${response.body}');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  Widget _buildModernMessageInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera/Attachment button
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: _iMessageBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _iMessageBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _pickAndSendImage,
                padding: EdgeInsets.zero,
                tooltip: 'Send Photo',
              ),
            ),
            
            // Message input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 36,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: _backgroundGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'iMessage',
                    hintStyle: TextStyle(
                      color: _textGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                  onChanged: (text) {
                    // Trigger UI update for send button state
                    setState(() {});
                  },
                ),
              ),
            ),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isNotEmpty 
                    ? _iMessageBlue 
                    : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: _messageController.text.trim().isNotEmpty
                    ? [
                        BoxShadow(
                          color: _iMessageBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: _messageController.text.trim().isNotEmpty 
                      ? Colors.white 
                      : Colors.grey[500],
                  size: 20,
                ),
                onPressed: _messageController.text.trim().isNotEmpty 
                    ? _sendMessage 
                    : null,
                padding: EdgeInsets.zero,
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
