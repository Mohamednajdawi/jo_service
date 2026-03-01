import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  static Future<void> openGoogleMapsNavigation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Create Google Maps navigation URL
      final String destination = address != null && address.isNotEmpty
          ? Uri.encodeComponent(address)
          : '$latitude,$longitude';
      
      final String url = 'https://www.google.com/maps/dir/?api=1&destination=$destination';
      
      // Try to launch the URL
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      throw Exception('Failed to open navigation: $e');
    }
  }

  static Future<void> openGoogleMapsLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Create Google Maps location URL
      final String destination = address != null && address.isNotEmpty
          ? Uri.encodeComponent(address)
          : '$latitude,$longitude';
      
      final String url = 'https://www.google.com/maps/search/?api=1&query=$destination';
      
      // Try to launch the URL
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      throw Exception('Failed to open location: $e');
    }
  }

  static Future<void> openAppleMapsNavigation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Create Apple Maps navigation URL
      final String destination = address != null && address.isNotEmpty
          ? Uri.encodeComponent(address)
          : '$latitude,$longitude';
      
      final String url = 'http://maps.apple.com/?daddr=$destination&dirflg=d';
      
      // Try to launch the URL
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to Google Maps
        await openGoogleMapsNavigation(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );
      }
    } catch (e) {
      // Fallback to Google Maps
      await openGoogleMapsNavigation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    }
  }
} 