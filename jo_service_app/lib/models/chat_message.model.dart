class ChatMessage {
  final String? id; // Message ID for deletion purposes
  final String senderId;
  final String senderType; // 'user' or 'provider'
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final bool isMe; // Flag to determine if the message was sent by the current user
  final String messageType; // 'text', 'image', 'booking_images'
  final List<String>? imageUrls; // URLs of images for image messages
  final String? bookingId; // Booking ID for booking-related messages

  ChatMessage({
    this.id,
    required this.senderId,
    required this.senderType,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.messageType = 'text',
    this.imageUrls,
    this.bookingId,
  });

  // Factory constructor to parse incoming message data (from WebSocket)
  factory ChatMessage.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    // Parse image URLs if present
    List<String>? imageUrls;
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    } else if (json['images'] != null) {
      imageUrls = List<String>.from(json['images']);
    }

    return ChatMessage(
      id: json['_id'] as String? ?? json['id'] as String?,
      senderId: json['senderId'] as String,
      senderType: json['senderType'] as String,
      recipientId: json['recipientId'] as String,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: json['senderId'] == currentUserId,
      messageType: json['messageType'] as String? ?? 'text',
      imageUrls: imageUrls,
      bookingId: json['bookingId'] as String?,
    );
  }

  // Helper method to check if this is an image message
  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  // Helper method to check if this is a booking-related message
  bool get isBookingMessage => messageType == 'booking_images' || bookingId != null;
}
