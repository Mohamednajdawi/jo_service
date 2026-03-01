class ApiConfig {
  // Production backend URL - Update this to your Railway backend URL
  static const String productionBaseUrl = 'https://joservice-backend.up.railway.app';

  // API endpoints
  static const String apiBaseUrl = '$productionBaseUrl/api';

  // WebSocket endpoints
  static const String wsBaseUrl = 'wss://joservice-backend.up.railway.app';

  // File uploads
  static const String uploadsBaseUrl = '$productionBaseUrl/uploads';

  // Profile pictures
  static const String profilePicturesBaseUrl = '$productionBaseUrl/uploads/profile-pictures';

  // Development backend URL (local)
  static const String developmentBaseUrl = 'http://10.46.6.68:3001/api';

  // Check if we're in production mode
  static bool get isProduction => true;
  static bool get isDevelopment => !isProduction;

  // Get appropriate base URL based on environment
  static String getBaseUrl() {
    if (isProduction) {
      return productionBaseUrl;
    } else {
      return developmentBaseUrl;
    }
  }
}
