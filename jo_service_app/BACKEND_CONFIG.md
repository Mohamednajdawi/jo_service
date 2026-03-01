# Backend Configuration

## Current Configuration

The Flutter app is currently configured to use the production backend:

- **Production Backend**: `https://joservicebackend-production.up.railway.app`
- **API Base URL**: `https://joservicebackend-production.up.railway.app/api`
- **WebSocket URL**: `wss://joservicebackend-production.up.railway.app`

## Configuration Files

### Main Configuration
- **File**: `lib/constants/api_config.dart`
- **Purpose**: Centralized configuration for all backend URLs
- **Usage**: Import and use the constants throughout the app

### Services Using Configuration
- `lib/services/api_service.dart` - Main API service
- `lib/services/chat_service.dart` - WebSocket chat service
- `lib/services/conversation_service.dart` - Chat conversations
- All other services use `ApiService.getBaseUrl()` automatically

## How to Change Backend URL

### Option 1: Update Production URL
Edit `lib/constants/api_config.dart`:
```dart
class ApiConfig {
  // Change this line to your new backend URL
  static const String productionBaseUrl = 'https://your-new-backend.com';
  
  // Other URLs will update automatically
  static const String apiBaseUrl = '$productionBaseUrl/api';
  static const String wsBaseUrl = 'wss://your-new-backend.com';
}
```

### Option 2: Add Environment-Specific URLs
Edit `lib/constants/api_config.dart`:
```dart
class ApiConfig {
  // Environment detection
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  // URLs based on environment
  static String get productionBaseUrl {
    if (isProduction) {
      return 'https://joservicebackend-production.up.railway.app';
    } else {
      return 'http://localhost:3001'; // Development
    }
  }
  
  static String get apiBaseUrl => '$productionBaseUrl/api';
  static String get wsBaseUrl => isProduction 
    ? 'wss://joservicebackend-production.up.railway.app'
    : 'ws://localhost:3001';
}
```

## Testing Configuration

After changing the configuration:

1. **Clean and rebuild** the app:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Test API endpoints** by logging in or fetching data

3. **Test WebSocket** by opening a chat conversation

4. **Test file uploads** by updating profile pictures

## Current Status

✅ **All backend endpoints updated to production**
✅ **WebSocket connections updated to production**
✅ **File upload URLs updated to production**
✅ **Centralized configuration created**
✅ **All services using centralized configuration**

## Notes

- The app now uses HTTPS for all production connections
- WebSocket connections use WSS (secure WebSocket)
- All file uploads will go to the production backend
- No more localhost or IP address dependencies
