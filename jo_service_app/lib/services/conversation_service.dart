import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/chat_conversation.dart';
import '../constants/api_config.dart';

class ConversationService {
  static String getBaseUrl() {
    // Production backend URL for all platforms
    return ApiConfig.productionBaseUrl;
  }

  static String get baseImageUrl => getBaseUrl();
  static String get apiUrl => '${getBaseUrl()}/api';

  // Get all conversations for the current user
  Future<List<ChatConversation>> getConversations({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final conversationsData = data['conversations'] as List;
        
        for (var conv in conversationsData) {
        }
        
        return conversationsData
            .map((conv) => ChatConversation.fromJson(conv))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load conversations');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Mark messages as read (for future implementation)
  Future<void> markAsRead({
    required String token,
    required String conversationId,
  }) async {
    // TODO: Implement when backend endpoint is available
  }

  // Delete conversation (for future implementation)
  Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    // TODO: Implement when backend endpoint is available
  }
}
