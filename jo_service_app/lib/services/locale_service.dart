import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService with ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
  ];
  
  Locale _currentLocale = const Locale('en', 'US'); // Default to English
  bool _isLoading = true; // Add loading state
  
  Locale get currentLocale => _currentLocale;
  bool get isLoading => _isLoading;
  
  // Check if current locale is RTL
  bool get isRTL => _currentLocale.languageCode == 'ar';
  
  // Get text direction based on locale
  TextDirection get textDirection => 
      isRTL ? TextDirection.rtl : TextDirection.ltr;
  
  LocaleService() {
    _loadLocale();
  }
  
  // Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);
      
      if (savedLocaleCode != null) {
        // Find the matching locale from supported locales
        final savedLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLocaleCode,
          orElse: () => const Locale('en', 'US'),
        );
        _currentLocale = savedLocale;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If there's an error loading, keep default locale
      print('Error loading locale: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change locale and save to SharedPreferences
  Future<void> changeLocale(Locale newLocale) async {
    if (_currentLocale == newLocale) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
      
      _currentLocale = newLocale;
      notifyListeners();
    } catch (e) {
      print('Error saving locale: $e');
    }
  }
  
  // Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = _currentLocale.languageCode == 'en' 
        ? const Locale('ar', 'SA')
        : const Locale('en', 'US');
    await changeLocale(newLocale);
  }
  
  // Get locale display name
  String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }
  
  // Get current locale display name
  String get currentLocaleDisplayName => getLocaleDisplayName(_currentLocale);
} 