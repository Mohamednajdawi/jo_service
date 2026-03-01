class ChatConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isOnline;
  final int unreadCount;
  final String? lastMessageSenderId;
  final String participantType; // 'user' or 'provider'
  final String? bookingId;
  final List<String> bookingPhotos;

  ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.isOnline = false,
    this.unreadCount = 0,
    this.lastMessageSenderId,
    this.participantType = 'provider',
    this.bookingId,
    this.bookingPhotos = const [],
  });

  // Create from booking data
  factory ChatConversation.fromBooking(Map<String, dynamic> booking, String currentUserId) {
    final provider = booking['provider'];
    final user = booking['user'];
    
    // Determine if current user is the user or provider in this booking
    final isCurrentUserTheUser = booking['user']?['_id'] == currentUserId;
    
    String participantId;
    String participantName;
    String? participantAvatar;
    String participantType;
    
    if (isCurrentUserTheUser) {
      // Current user is the customer, so participant is the provider
      participantId = provider?['_id'] ?? '';
      participantName = provider?['fullName'] ?? provider?['businessName'] ?? 'Provider';
      participantAvatar = provider?['profilePictureUrl'];
      participantType = 'provider';
    } else {
      // Current user is the provider, so participant is the customer
      participantId = user?['_id'] ?? '';
      participantName = user?['fullName'] ?? 'Customer';
      participantAvatar = user?['profilePictureUrl'];
      participantType = 'user';
    }

    return ChatConversation(
      id: booking['_id'] ?? '',
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      participantType: participantType,
      lastMessage: 'Tap to start chatting',
      lastMessageTime: DateTime.tryParse(booking['createdAt'] ?? ''),
      isOnline: false,
      unreadCount: 0,
    );
  }

  // Create from JSON (API response format)
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    // Extract booking photos
    
    final bookingData = json['booking'] as Map<String, dynamic>?;
    
    final photos = bookingData?['photos'] as List?;
    
    final photoUrls = photos?.map((photo) => photo.toString()).toList() ?? [];

    return ChatConversation(
      id: json['id'] ?? '',
      participantId: json['participantId'] ?? '',
      participantName: json['participantName'] ?? '',
      participantAvatar: json['participantAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      isOnline: json['isOnline'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageSenderId: json['lastMessageSenderId'],
      participantType: json['participantType'] ?? 'provider',
      bookingId: json['booking'] != null ? json['booking']['_id'] : null,
      bookingPhotos: photoUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'isOnline': isOnline,
      'unreadCount': unreadCount,
      'lastMessageSenderId': lastMessageSenderId,
      'participantType': participantType,
    };
  }

  // Helper method to get formatted time
  String get formattedTime {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = lastMessageTime!.hour;
      final minute = lastMessageTime!.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[lastMessageTime!.weekday - 1];
    } else {
      // Older - show date
      final day = lastMessageTime!.day.toString().padLeft(2, '0');
      final month = lastMessageTime!.month.toString().padLeft(2, '0');
      final year = lastMessageTime!.year;
      return '$day/$month/$year';
    }
  }

  // Helper method to get initials for avatar
  String get initials {
    if (participantName.isEmpty) return 'U';
    final names = participantName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return participantName[0].toUpperCase();
  }

  // Helper method to check if message was sent by current user
  bool isLastMessageFromMe(String currentUserId) {
    return lastMessageSenderId == currentUserId;
  }
}
