import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/conversation_service.dart';
import '../models/chat_message.model.dart';
import '../models/chat_conversation.dart';
import './chat_screen.dart';

class ProviderMessagesScreen extends StatefulWidget {
  const ProviderMessagesScreen({super.key});

  @override
  State<ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends State<ProviderMessagesScreen> {
  final ApiService _apiService = ApiService();
  final BookingService _bookingService = BookingService();
  final ConversationService _conversationService = ConversationService();
  late final AuthService _authService;
  bool _isLoading = true;
  List<ChatConversation> _conversations = [];
  String? _currentProviderId;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      _currentProviderId = await _authService.getUserId();

      if (token == null || token.isEmpty || _currentProviderId == null) {
              if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationTokenMissing)),
        );
      }
        setState(() => _isLoading = false);
        return;
      }

      // Use the ConversationService to get conversations
            final conversations = await _conversationService.getConversations(token: token);

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadConversations}: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          l10n.providerMessagesTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadConversations,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState(isDark)
              : _buildConversationsList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMessagesYet,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noConversationsMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation, isDark);
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation, bool isDark) {
    final avatarUrl = conversation.participantAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Participant Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                                                                  backgroundImage: hasAvatar ? NetworkImage('${ConversationService.baseImageUrl}/$avatarUrl') : null,
                      child: !hasAvatar
                          ? Text(
                              conversation.initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007AFF),
                              ),
                            )
                          : null,
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Conversation Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.participantName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            conversation.formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage ?? 'No messages yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(ChatConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    ).then((_) => _loadConversations()); // Refresh when returning
  }


}


