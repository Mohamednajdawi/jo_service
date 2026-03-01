import '../constants/api_config.dart';

/// Builds a loadable URL for a booking photo (from DB).
/// Handles full URL, relative path, or host-without-protocol.
String bookingPhotoUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  final base = ApiConfig.productionBaseUrl;
  if (path.startsWith(base)) return path;
  if (path.startsWith('http')) return path;
  if (!path.startsWith('/')) return 'https://$path';
  return '$base$path';
}
