import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './api_service.dart'; // To use getBaseUrl
import './oauth_service.dart'; // Added for social login
import 'package:flutter/material.dart'; // Added for ChangeNotifier

// UserInfo class to hold basic user details after login
class UserInfo {
  final String id;
  final String email;
  final String fullName;
  // Add other fields you might want to store globally, e.g., profilePictureUrl

  UserInfo({required this.id, required this.email, required this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? json['id'] as String, // Handle both _id and id
      email: json['email'] as String,
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
    };
  }
}

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  String get _authBaseUrl => "${ApiService.getBaseUrl()}/auth";
  String get _apiBaseUrl => ApiService.getBaseUrl(); // getBaseUrl() already includes /api

  // Using more specific keys for clarity with new _saveAuthData logic
  static const String _tokenKey = 'auth_token_key';
  static const String _userTypeKey = 'user_type_key';
  static const String _userInfoKey = 'user_info_key';

  String? _token;
  String? _userType;
  UserInfo? _userInfo;
  bool _isAuthenticated = false;
  bool _isLoading =
      true; // Start with loading true until _loadAuthData completes

  String? get token => _token;
  String? get userType => _userType;
  UserInfo? get userInfo => _userInfo;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _token = await _storage.read(key: _tokenKey);
    _userType = await _storage.read(key: _userTypeKey);
    final userInfoString = await _storage.read(key: _userInfoKey);
    if (userInfoString != null) {
      try {
        _userInfo = UserInfo.fromJson(json.decode(userInfoString));
      } catch (e) {
        await _storage.delete(key: _userInfoKey); // Clear corrupted data
      }
    }
    _isAuthenticated = _token != null &&
        _token!.isNotEmpty &&
        _userType != null &&
        _userType!.isNotEmpty;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAuthData(
      String token, String userType, UserInfo userInfo) async {
    _isLoading = true;
    notifyListeners(); // Notify UI that an auth operation is starting

    _token = token;
    _userType = userType;
    _userInfo = userInfo;
    _isAuthenticated = true;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userTypeKey, value: userType);
    await _storage.write(
        key: _userInfoKey, value: json.encode(userInfo.toJson()));

    // User authenticated successfully
    print('AuthService: User authenticated - ${userInfo.id} (${userType})');

    _isLoading = false;
    notifyListeners(); // Notify UI that auth operation completed and state updated
  }

  Future<void> clearAuthData() async {
    _isLoading = true;
    notifyListeners();

    _token = null;
    _userType = null;
    _userInfo = null;
    _isAuthenticated = false;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _userInfoKey);

    // User logged out - all data cleared
    print('AuthService: User logged out - clearing all data');

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> getToken() async {
    return _token; // Return loaded token, no need to read from storage again if loaded
  }

  Future<String?> getUserType() async {
    return _userType; // Return loaded user type
  }

  Future<String?> getUserId() async {
    return _userInfo?.id; // Return loaded user ID
  }

  Future<Map<String, dynamic>> registerProvider({
    required String email,
    required String password,
    String? fullName,
    String? companyName, // Added for provider registration
    required String serviceType,
    String? hourlyRate, // Added hourlyRate parameter (as String)
    String? city, // Added city parameter
    String? addressText, // Added addressText parameter
    // Add other fields as necessary from your Provider model & backend controller
    // e.g., hourlyRate, locationLatitude, locationLongitude, addressText, etc.
  }) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/provider/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'companyName': companyName, // Added
        'serviceType': serviceType,
        'hourlyRate': hourlyRate, // Added hourlyRate to JSON body
        'city': city, // Add city to JSON body
        'addressText': addressText, // Add addressText to JSON body
        // Populate other fields here
      }),
    ).timeout(const Duration(seconds: 10));

    final responseData = json.decode(response.body);
    if (response.statusCode == 201 && responseData['token'] != null) {
      await _saveAuthData(
          responseData['token'],
          'provider',
          UserInfo(
              id: responseData['provider']['_id'],
              email: email,
              fullName: fullName ?? ''));
      return responseData; // Contains provider and token
    } else {
      throw Exception(responseData['message'] ?? 'Failed to register provider');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/user/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profilePictureUrl': profilePictureUrl,
      }),
    ).timeout(const Duration(seconds: 10));

    final responseData = json.decode(response.body);
    if (response.statusCode == 201) {
      // Check if verification is required
      if (responseData['verificationRequired'] == true) {
        // Return verification data without saving auth data
        return {
          ...responseData,
          'verificationRequired': true,
          'userId': responseData['user']['_id'],
        };
      } else if (responseData['token'] != null) {
        // Legacy case - user is immediately verified
        await _saveAuthData(
            responseData['token'],
            'user',
            UserInfo(
                id: responseData['user']['_id'],
                email: email,
                fullName: fullName ?? ''));
        return responseData;
      }
    }
    
    // If we reach here, something went wrong
    throw Exception(responseData['message'] ?? 'Failed to register user');
  }

  Future<Map<String, dynamic>> loginUser(
      {required String email, required String password}) async {
    try {
      // First try user login
      final userResponse = await http.post(
        Uri.parse('$_authBaseUrl/user/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final userResponseData = json.decode(userResponse.body);
      
      if (userResponse.statusCode == 200 && userResponseData['token'] != null) {
        // User login successful
        await _saveAuthData(
            userResponseData['token'],
            'user',
            UserInfo(
                id: userResponseData['user']['_id'],
                email: email,
                fullName: userResponseData['user']['fullName']));
        return userResponseData;
      } else {
        // User login failed, try provider login
        try {
          final providerResponse = await http.post(
            Uri.parse('$_authBaseUrl/provider/login'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'email': email,
              'password': password,
            }),
          ).timeout(const Duration(seconds: 10));

          final providerResponseData = json.decode(providerResponse.body);
          
          if (providerResponse.statusCode == 200 && providerResponseData['token'] != null) {
            // Provider login successful
            await _saveAuthData(
                providerResponseData['token'],
                'provider',
                UserInfo(
                    id: providerResponseData['provider']['_id'],
                    email: email,
                    fullName: providerResponseData['provider']['fullName']));
            return {
              'message': 'Provider logged in successfully',
              'user': providerResponseData['provider'], // Keep same structure for compatibility
              'token': providerResponseData['token'],
              'userType': 'provider' // Add flag to identify this is a provider
            };
          } else {
            throw Exception(providerResponseData['message'] ?? 'Invalid credentials');
          }
        } catch (providerError) {
          // Both user and provider login failed
          throw Exception('Invalid credentials');
        }
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your network connection.');
      }
      if (e.toString().contains('Invalid credentials')) {
        throw Exception('Invalid credentials');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> loginProvider(
      {required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$_authBaseUrl/provider/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10)); // Add 10-second timeout

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['token'] != null) {
        await _saveAuthData(
            responseData['token'],
            'provider',
            UserInfo(
                id: responseData['provider']['_id'],
                email: email,
                fullName: responseData['provider']['fullName']));
        return responseData; // Contains provider and token
      } else {
        throw Exception(responseData['message'] ?? 'Failed to login provider');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your network connection.');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Social Login Methods
  // Facebook OAuth removed - only Google OAuth is supported

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final result = await OAuthService.signInWithGoogle();
      
      if (result != null && result['success'] == true) {
        // Save authentication data
        await _saveAuthData(
          result['token'],
          'user', // Assume user type for social login
          UserInfo(
            id: result['user']['_id'] ?? result['user']['id'],
            email: result['user']['email'],
            fullName: result['user']['fullName'] ?? result['user']['displayName'] ?? '',
          ),
        );
        return result;
      } else {
        throw Exception(result?['message'] ?? 'Google login failed');
      }
    } catch (e) {
      throw Exception('Google login error: $e');
    }
  }

  Future<void> logout() async {
    // Sign out from social accounts
    await OAuthService.signOut();
    await clearAuthData();
    // _isLoading and notifyListeners are handled in clearAuthData
  }

  Future<void> deleteAccount() async {
    try {
      // Ensure we have valid authentication
      if (_token == null || _userType == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      // Refresh token from storage to ensure we have the latest
      await _loadAuthData();
      
      if (_token == null || _userType == null) {
        throw Exception('Authentication expired. Please log in again.');
      }

      final endpoint = _userType == 'user' ? 'users/me' : 'providers/me';
      final url = '$_apiBaseUrl/$endpoint';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 10));

      // Debug information
      print('DELETE Account - Status: ${response.statusCode}');
      print('DELETE Account - Body: ${response.body}');
      print('DELETE Account - Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Account deleted successfully, clear local data
        await clearAuthData();
      } else if (response.statusCode == 401) {
        // Authentication failed - token is invalid or expired
        await clearAuthData(); // Clear invalid auth data
        throw Exception('Your session has expired. Please log in again to delete your account.');
      } else if (response.statusCode == 403) {
        // Forbidden - user doesn't have permission
        throw Exception('You do not have permission to delete this account.');
      } else {
        // Handle other error responses
        String errorMessage = 'Failed to delete account';
        try {
          // Try to parse as JSON first
          final responseData = json.decode(response.body);
          errorMessage = responseData['message'] ?? 'Failed to delete account';
        } catch (e) {
          // If JSON parsing fails, check if it's HTML or plain text
          if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html>')) {
            errorMessage = 'Server error occurred. Please try again later.';
          } else {
            errorMessage = response.body.isNotEmpty ? response.body : 'Failed to delete account';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your network connection.');
      }
      throw Exception('Error deleting account: ${e.toString()}');
    }
  }
}
