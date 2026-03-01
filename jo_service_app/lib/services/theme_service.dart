import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/theme.dart';

class ThemeService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _locationServicesKey = 'location_services_enabled';

  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _isLoading = true;

  ThemeData _currentTheme = AppTheme.lightTheme;

  bool get darkModeEnabled => _darkModeEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationServicesEnabled => _locationServicesEnabled;
  bool get isLoading => _isLoading;
  ThemeData get currentTheme => _currentTheme;

  ThemeService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final darkModeStr = await _storage.read(key: _darkModeKey);
    final notificationsStr = await _storage.read(key: _notificationsKey);
    final locationServicesStr = await _storage.read(key: _locationServicesKey);

    _darkModeEnabled = darkModeStr == 'true';
    _notificationsEnabled =
        notificationsStr == null || notificationsStr == 'true';
    _locationServicesEnabled =
        locationServicesStr == null || locationServicesStr == 'true';

    _updateTheme();
    _isLoading = false;
    notifyListeners();
  }

  void _updateTheme() {
    _currentTheme = _darkModeEnabled ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _storage.write(key: _darkModeKey, value: value.toString());
    _updateTheme();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(key: _notificationsKey, value: value.toString());
    notifyListeners();
  }

  Future<void> toggleLocationServices(bool value) async {
    _locationServicesEnabled = value;
    await _storage.write(key: _locationServicesKey, value: value.toString());
    notifyListeners();
  }
}
