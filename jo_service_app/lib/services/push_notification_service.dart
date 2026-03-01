import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  // Stream controllers for notification events
  final StreamController<Map<String, dynamic>> _onNotificationTappedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTapped => _onNotificationTappedController.stream;

  Future<void> initialize() async {
    try {
      print('Initializing local notifications only...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      print('Local notifications initialized successfully');
    } catch (error) {
      print('Error initializing local notifications: $error');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'jo_service_channel',
        'JO Service Notifications',
        description: 'Notifications for booking updates, messages, and other important updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _onNotificationTappedController.add(data);
      _navigateToScreen(data);
    }
  }

  // Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_channel',
      'JO Service Notifications',
      channelDescription: 'Notifications for booking updates, messages, and other important updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    // This will be handled by the app's navigation system
    // The navigation logic should be implemented in the main app
    print('Navigate to screen based on notification data: $data');
  }

  Future<void> sendTestNotification() async {
    try {
      await _apiService.post('/notifications/test', {});
      print('Test notification sent successfully');
    } catch (error) {
      print('Error sending test notification: $error');
    }
  }

  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final response = await _apiService.get('/notifications/settings');
      return response['data']['notificationSettings'];
    } catch (error) {
      print('Error getting notification settings: $error');
      return null;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      await _apiService.put('/notifications/settings', {
        'notificationSettings': settings,
      });
      print('Notification settings updated successfully');
      return true;
    } catch (error) {
      print('Error updating notification settings: $error');
      return false;
    }
  }

  // Schedule a notification for later
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    // This would be implemented with flutter_local_notifications scheduling
    // For now, just show immediately as an example
    await showLocalNotification(
      title: title,
      body: body,
      data: data,
      id: id,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  void dispose() {
    _onNotificationTappedController.close();
  }
} 