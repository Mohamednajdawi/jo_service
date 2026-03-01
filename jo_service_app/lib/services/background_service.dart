import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define the callback dispatcher - this must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    switch (task) {
      case 'syncData':
        return _performDataSync();
      case 'checkBookingUpdates':
        return _checkBookingUpdates();
      default:
        return Future.value(true);
    }
  });
}

// Background task to sync data
Future<bool> _performDataSync() async {
  try {
    // Add your data sync logic here
    
    // Example: sync user bookings, provider updates, etc.
    // You can make API calls here to sync data
    
    return true;
  } catch (e) {
    return false;
  }
}

// Background task to check for booking updates
Future<bool> _checkBookingUpdates() async {
  try {
    
    // Get stored auth token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    
    if (token != null) {
      // Example API call to check for updates
      // final response = await http.get(
      //   Uri.parse('YOUR_API_ENDPOINT/bookings/updates'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );
      
      // If there are updates, show notification
      // _showNotification('New Booking Update', 'You have new booking updates');
    }
    
    return true;
  } catch (e) {
    return false;
  }
}

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialize background service
  static Future<void> initialize() async {
    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false in production
    );

    // Initialize notifications
    await _initializeNotifications();
  }

  // Initialize local notifications
  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);
  }

  // Start background tasks
  static Future<void> startBackgroundTasks() async {
    try {
      // Check if running on supported platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        if (kDebugMode) {
        }
        return;
      }

      // For iOS, periodic tasks have limitations
      if (Platform.isIOS) {
        if (kDebugMode) {
        }
        // iOS doesn't support true periodic background tasks like Android
        // You might want to use push notifications or background app refresh instead
        return;
      }

      // Register periodic task for data sync (runs every 15 minutes) - Android only
      if (Platform.isAndroid) {
        await Workmanager().registerPeriodicTask(
          "dataSync",
          "syncData",
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );

        // Register periodic task for booking updates (runs every 30 minutes)
        await Workmanager().registerPeriodicTask(
          "bookingUpdates",
          "checkBookingUpdates",
          frequency: const Duration(minutes: 30),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
      }
      // Fallback: Use alternative approach like push notifications
      _handleBackgroundTaskError(e);
    }
  }

  // Handle background task registration errors
  static void _handleBackgroundTaskError(dynamic error) {
    if (kDebugMode) {
    }
    // You could implement alternative notification strategies here
    // such as using local notifications or third-party services
  }

  // Stop all background tasks
  static Future<void> stopBackgroundTasks() async {
    await Workmanager().cancelAll();
  }

  // Show local notification
  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jo_service_channel',
      'JO Service Notifications',
      channelDescription: 'Notifications for JO Service app updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Save app state when going to background
  static Future<void> saveAppState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active', DateTime.now().toIso8601String());
    await prefs.setBool('was_running_in_background', true);
  }

  // Restore app state when coming back from background
  static Future<Map<String, dynamic>> getAppState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'last_active': prefs.getString('last_active'),
      'was_running_in_background': prefs.getBool('was_running_in_background') ?? false,
    };
  }
}
