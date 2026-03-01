import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/booking_model.dart';
import './api_service.dart';
import './auth_service.dart';

class BookingService {
  final String _baseUrl = '${ApiService.getBaseUrl()}/bookings';

  // Create a new booking, with or without photos
  Future<Booking> createBooking({
    required String token,
    required String providerId,
    required DateTime serviceDateTime,
    String? serviceLocationDetails,
    String? userNotes,
    List<String>? photoPaths, // Changed to List<String>
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['providerId'] = providerId;
      request.fields['serviceDateTime'] = serviceDateTime.toUtc().toIso8601String();
      if (serviceLocationDetails != null) {
        request.fields['serviceLocationDetails'] = serviceLocationDetails;
      }
      if (userNotes != null) {
        request.fields['userNotes'] = userNotes;
      }

      // Add photo files if paths are provided
      if (photoPaths != null && photoPaths.isNotEmpty) {
        for (var path in photoPaths) {
          request.files.add(await http.MultipartFile.fromPath('photos', path));
        }
      }


      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 201) {
        return Booking.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create booking.');
    }
  }

  // Get bookings for the logged-in user
  Future<Map<String, dynamic>> getUserBookings({
    required String token,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl/user');

      // Add query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      url = url.replace(queryParameters: queryParams);


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Convert the list of bookings to Booking objects
        final List<dynamic> bookingsJson = data['bookings'] ?? [];
        final List<Booking> bookings = [];


        // If no bookings found, try the fallback test endpoint
        if (bookingsJson.isEmpty) {
          return await _getUserBookingsFallback(token);
        }

        // Safely process each booking
        for (var json in bookingsJson) {
          try {
            // Handle both string IDs and full booking objects
            if (json is String) {
              // If the API returns just an ID string
              bookings.add(Booking(
                id: json,
                serviceDateTime: DateTime.now(),
                status: 'pending',
              ));
            } else if (json is Map<String, dynamic>) {
              // If the API returns a full booking object
              bookings.add(Booking.fromJson(json));
            }
          } catch (e) {
            // Skip invalid bookings
          }
        }


        return {
          'bookings': bookings,
          'currentPage': data['currentPage'] ?? page,
          'totalPages': data['totalPages'] ?? 1,
          'totalBookings': data['totalBookings'] ?? bookings.length,
        };
      } else {
        // Try fallback method if main endpoint fails
        return await _getUserBookingsFallback(token);
      }
    } catch (e) {
      // Try fallback method if main endpoint throws an exception
      return await _getUserBookingsFallback(token);
    }
  }

  // Fallback method to get bookings when the main endpoint fails
  Future<Map<String, dynamic>> _getUserBookingsFallback(String token) async {
    try {

      // Get the user ID from the token
      final userId = await _getUserIdFromToken(token);
      if (userId == null) {
        throw Exception('Could not extract user ID from token');
      }

      // Use the explicit method to get bookings by user ID
      final bookings = await getBookingsByUserId(token: token, userId: userId);

      return {
        'bookings': bookings,
        'currentPage': 1,
        'totalPages': 1,
        'totalBookings': bookings.length,
      };
    } catch (e) {
      throw Exception('Error loading bookings: $e');
    }
  }

  // Helper to extract user ID from token
  Future<String?> _getUserIdFromToken(String token) async {
    try {
      // First try to get it from AuthService
      final authService = AuthService();
      final userId = await authService.getUserId();
      if (userId != null) {
        return userId;
      }

      // If that fails, make a request to get user profile
      final response = await http.get(
        Uri.parse('${ApiService.getBaseUrl()}/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['_id'] ?? data['id'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get bookings for the logged-in provider
  Future<Map<String, dynamic>> getProviderBookings({
    required String token,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl/provider');

      // Add query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      url = url.replace(queryParameters: queryParams);


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Convert the list of bookings to Booking objects
        final List<dynamic> bookingsJson = data['bookings'] ?? [];
        final List<Booking> bookings = [];


        // If no bookings found, try the fallback test endpoint
        if (bookingsJson.isEmpty) {
          return await _getProviderBookingsFallback(token);
        }

        // Safely process each booking
        for (var json in bookingsJson) {
          try {
            // Handle both string IDs and full booking objects
            if (json is String) {
              // If the API returns just an ID string
              bookings.add(Booking(
                id: json,
                serviceDateTime: DateTime.now(),
                status: 'pending',
              ));
            } else if (json is Map<String, dynamic>) {
              // If the API returns a full booking object
              bookings.add(Booking.fromJson(json));
            }
          } catch (e) {
            // Skip invalid bookings
          }
        }


        return {
          'bookings': bookings,
          'currentPage': data['currentPage'] ?? page,
          'totalPages': data['totalPages'] ?? 1,
          'totalBookings': data['totalBookings'] ?? bookings.length,
        };
      } else {
        // Try fallback method if main endpoint fails
        return await _getProviderBookingsFallback(token);
      }
    } catch (e) {
      // Try fallback method if main endpoint throws an exception
      return await _getProviderBookingsFallback(token);
    }
  }

  // Fallback method to get provider bookings when the main endpoint fails
  Future<Map<String, dynamic>> _getProviderBookingsFallback(
      String token) async {
    try {

      // Get the provider ID from the token
      final providerId = await _getUserIdFromToken(token);
      if (providerId == null) {
        throw Exception('Could not extract provider ID from token');
      }

      // Use the explicit method to get bookings by provider ID
      final bookings =
          await getBookingsByProviderId(token: token, providerId: providerId);

      return {
        'bookings': bookings,
        'currentPage': 1,
        'totalPages': 1,
        'totalBookings': bookings.length,
      };
    } catch (e) {
      throw Exception('Error loading provider bookings: $e');
    }
  }

  // Get a specific booking by ID
  Future<Booking> getBookingById({
    required String token,
    required String bookingId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$bookingId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle different response formats
        if (responseData is String) {
          // If the API returns just the ID as a string
          return Booking(
            id: responseData,
            serviceDateTime: DateTime.now(),
            status: 'pending',
          );
        } else if (responseData is Map<String, dynamic>) {
          // If the API returns a full booking object
          return Booking.fromJson(responseData);
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load booking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading booking: $e');
    }
  }

  // Update booking status
  Future<Booking> updateBookingStatus({
    required String token,
    required String bookingId,
    required String status,
  }) async {
    try {

      final response = await http.patch(
        Uri.parse('$_baseUrl/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );


      if (response.statusCode == 200) {
        return Booking.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to update booking status';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error updating booking status: $e');
    }
  }

  // Fetch all bookings directly (not relying on token's user ID)
  Future<List<Booking>> fetchAllBookingsForTests({
    required String token,
  }) async {
    try {

      // This is a test method to see all bookings in the system
      final response = await http.get(
        Uri.parse('${ApiService.getBaseUrl()}/bookings/test-all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> bookingsJson = data['bookings'] ?? [];


        final List<Booking> bookings = [];

        // Safely process each booking
        for (var json in bookingsJson) {
          try {
            if (json is String) {
              bookings.add(Booking(
                id: json,
                serviceDateTime: DateTime.now(),
                status: 'pending',
              ));
            } else if (json is Map<String, dynamic>) {
              bookings.add(Booking.fromJson(json));
            }
          } catch (e) {
          }
        }


        return bookings;
      } else {
        throw Exception('Failed to load all bookings: ${response.body}');
      }
    } catch (e) {
      return [];
    }
  }

  // Explicit method to get bookings by user ID (direct debug endpoint)
  Future<List<Booking>> getBookingsByUserId({
    required String token,
    required String userId,
  }) async {
    try {

      final response = await http.get(
        Uri.parse('$_baseUrl/by-user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> bookingsJson = data['bookings'] ?? [];


        final List<Booking> bookings = [];

        // Process bookings
        for (var json in bookingsJson) {
          try {
            if (json is Map<String, dynamic>) {
              bookings.add(Booking.fromJson(json));
            }
          } catch (e) {
          }
        }


        return bookings;
      } else {
        throw Exception('Failed to load bookings by user ID: ${response.body}');
      }
    } catch (e) {
      return [];
    }
  }

  // Explicit method to get bookings by provider ID (direct debug endpoint)
  Future<List<Booking>> getBookingsByProviderId({
    required String token,
    required String providerId,
  }) async {
    try {

      final response = await http.get(
        Uri.parse('$_baseUrl/by-provider/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> bookingsJson = data['bookings'] ?? [];


        final List<Booking> bookings = [];

        // Process bookings
        for (var json in bookingsJson) {
          try {
            if (json is Map<String, dynamic>) {
              bookings.add(Booking.fromJson(json));
            }
          } catch (e) {
          }
        }


        return bookings;
      } else {
        throw Exception(
            'Failed to load bookings by provider ID: ${response.body}');
      }
    } catch (e) {
      return [];
    }
  }

  // Method to reassign a booking to a different provider (for debugging/testing)
  Future<Booking> reassignBookingToProvider({
    required String token,
    required String bookingId,
    required String providerId,
  }) async {
    try {

      // Create a custom endpoint for reassignment
      final response = await http.patch(
        Uri.parse('$_baseUrl/$bookingId/reassign'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
        }),
      );


      if (response.statusCode == 200) {
        return Booking.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to reassign booking';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error reassigning booking: $e');
    }
  }
}
