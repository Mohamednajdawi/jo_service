import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class OAuthService {
  static String get _baseUrl => ApiService.getBaseUrl();

  // Google OAuth
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger the sign-in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign in was cancelled',
        };
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Get user data
      final userData = {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      };

      // Exchange Google token for our server token
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/oauth/google/callback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accessToken': googleAuth.accessToken,
          'idToken': googleAuth.idToken,
          'userData': userData,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Google login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign in error: $e',
      };
    }
  }

  // Sign out from social accounts
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      // Ignore errors during sign out
      print('Error during social sign out: $e');
    }
  }

  // Check if user is signed in to any social account
  static Future<bool> isSignedIn() async {
    try {
      // Check Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.isSignedIn();
      if (googleUser) return true;
      
      return false;
    } catch (e) {
      return false;
    }
  }
}
