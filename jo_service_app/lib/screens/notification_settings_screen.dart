import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/push_notification_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final LocalNotificationService _notificationService = LocalNotificationService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Notification settings
  bool _bookingUpdates = true;
  bool _chatMessages = true;
  bool _ratings = true;
  bool _promotions = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      if (settings != null) {
        setState(() {
          _bookingUpdates = settings['bookingUpdates'] ?? true;
          _chatMessages = settings['chatMessages'] ?? true;
          _ratings = settings['ratings'] ?? true;
          _promotions = settings['promotions'] ?? true;
        });
      }
    } catch (error) {
      print('Error loading notification settings: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _notificationService.updateNotificationSettings({
        'bookingUpdates': _bookingUpdates,
        'chatMessages': _chatMessages,
        'ratings': _ratings,
        'promotions': _promotions,
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.settingsSaved),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSavingSettings),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingSettings),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      // Show a local test notification
      await _notificationService.showLocalNotification(
        title: 'Test Notification',
        body: 'This is a test notification from JO Service App',
        data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.testNotificationSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSendingTestNotification),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    l10n.notificationPreferences,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notificationPreferencesDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildNotificationSetting(
                            title: l10n.bookingUpdates,
                            description: l10n.bookingUpdatesDescription,
                            value: _bookingUpdates,
                            onChanged: (value) {
                              setState(() {
                                _bookingUpdates = value;
                              });
                            },
                          ),
                          const Divider(),
                          _buildNotificationSetting(
                            title: l10n.chatMessages,
                            description: l10n.chatMessagesDescription,
                            value: _chatMessages,
                            onChanged: (value) {
                              setState(() {
                                _chatMessages = value;
                              });
                            },
                          ),
                          const Divider(),
                          _buildNotificationSetting(
                            title: l10n.ratings,
                            description: l10n.ratingsDescription,
                            value: _ratings,
                            onChanged: (value) {
                              setState(() {
                                _ratings = value;
                              });
                            },
                          ),
                          const Divider(),
                          _buildNotificationSetting(
                            title: l10n.promotions,
                            description: l10n.promotionsDescription,
                            value: _promotions,
                            onChanged: (value) {
                              setState(() {
                                _promotions = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNotificationSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(l10n.saveSettings),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _sendTestNotification,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.sendTestNotification),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Additional Information
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.notificationInfo,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.notificationInfoDescription,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSetting({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
} 