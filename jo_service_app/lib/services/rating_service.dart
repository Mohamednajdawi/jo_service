import 'dart:convert';
import 'package:http/http.dart' as http;
import './api_service.dart';
import '../models/rating_model.dart';

class RatingService {
  final String _baseUrl = '${ApiService.getBaseUrl()}/ratings';

  // Submit a multi-criteria rating for a provider
  Future<void> rateProvider({
    required String token,
    required String bookingId,
    required String providerId,
    required double punctuality,
    required double workQuality,
    required double speedAndEfficiency,
    required double cleanliness,
    String? review,
  }) async {
    try {
      // Calculate overall rating from individual criteria
      final overallRating = Rating.calculateOverallRating(
        punctuality: punctuality,
        workQuality: workQuality,
        speedAndEfficiency: speedAndEfficiency,
        cleanliness: cleanliness,
      );


      final response = await http.post(
        Uri.parse('$_baseUrl/provider'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
          'bookingId': bookingId,
          'punctuality': punctuality,
          'workQuality': workQuality,
          'speedAndEfficiency': speedAndEfficiency,
          'cleanliness': cleanliness,
          'overallRating': overallRating,
          'review': review,
        }),
      );


      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to submit rating';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error submitting rating: $e');
    }
  }

  // Legacy method for backward compatibility - sends only the fields backend expects
  Future<void> rateProviderLegacy({
    required String token,
    required String bookingId,
    required String providerId,
    required double rating,
    String? review,
  }) async {
    try {

      final response = await http.post(
        Uri.parse('$_baseUrl/provider'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
          'bookingId': bookingId,
          'rating': rating,
          if (review != null && review.isNotEmpty) 'review': review,
        }),
      );


      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to submit rating';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error submitting legacy rating: $e');
    }
  }

  // Check if a user has already rated a booking
  Future<bool> checkIfUserHasRated({
    required String token,
    required String bookingId,
  }) async {
    try {

      final response = await http.get(
        Uri.parse('$_baseUrl/check/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasRated'] ?? false;
      } else {
        // If the endpoint doesn't exist yet, default to false
        return false;
      }
    } catch (e) {
      // Default to false if there's an error
      return false;
    }
  }

  // Get detailed ratings and statistics for a provider
  Future<ProviderRatingStats> getProviderRatingStats({
    required String token,
    required String providerId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/provider/$providerId/stats');


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProviderRatingStats.fromJson(data);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to get provider rating stats';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error getting provider rating stats: $e');
    }
  }

  // Get ratings for a provider (legacy method for backward compatibility)
  Future<Map<String, dynamic>> getProviderRatings({
    required String token,
    required String providerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl/provider/$providerId');

      // Add query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      url = url.replace(queryParameters: queryParams);


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to get provider ratings';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error getting provider ratings: $e');
    }
  }

  // Get individual ratings list for a provider
  Future<List<Rating>> getProviderRatingsList({
    required String token,
    required String providerId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl/provider/$providerId/list');

      // Add query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      url = url.replace(queryParameters: queryParams);


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ratings'] is List) {
          return (data['ratings'] as List)
              .map((rating) => Rating.fromJson(rating as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to get provider ratings list';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error getting provider ratings list: $e');
    }
  }
}
