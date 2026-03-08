import 'package:flutter_test/flutter_test';
import 'package:jo_service_app/constants/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('should have correct production base URL', () {
      expect(
        ApiConfig.productionBaseUrl,
        'https://joservice-production.up.railway.app',
      );
    });

    test('should have correct development base URL', () {
      expect(
        ApiConfig.developmentBaseUrl,
        'http://localhost:3000/api',
      );
    });

    test('should have correct API base URL', () {
      expect(
        ApiConfig.apiBaseUrl,
        'https://joservice-production.up.railway.app/api',
      );
    });

    test('should have correct WebSocket URL', () {
      expect(
        ApiConfig.wsBaseUrl,
        'wss://joservice-production.up.railway.app',
      );
    });

    test('should have correct uploads base URL', () {
      expect(
        ApiConfig.uploadsBaseUrl,
        'https://joservice-production.up.railway.app/uploads',
      );
    });

    test('should have correct profile pictures URL', () {
      expect(
        ApiConfig.profilePicturesBaseUrl,
        'https://joservice-production.up.railway.app/uploads/profile-pictures',
      );
    });

    test('isProduction should return true', () {
      expect(ApiConfig.isProduction, true);
    });

    test('isDevelopment should return false', () {
      expect(ApiConfig.isDevelopment, false);
    });

    test('getBaseUrl should return production URL in production mode', () {
      expect(
        ApiConfig.getBaseUrl(),
        'https://joservice-production.up.railway.app',
      );
    });
  });

  group('URL Validation', () {
    test('production URL should be valid HTTPS', () {
      expect(ApiConfig.productionBaseUrl.startsWith('https://'), true);
    });

    test('WebSocket URL should use wss protocol', () {
      expect(ApiConfig.wsBaseUrl.startsWith('wss://'), true);
    });
  });
}