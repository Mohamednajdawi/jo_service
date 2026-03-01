class ProviderLocation {
  final String? addressText;
  final String? city; // Add city field for location filtering
  final List<double>? coordinates; // longitude, latitude

  ProviderLocation({this.addressText, this.city, this.coordinates});

  factory ProviderLocation.fromJson(Map<String, dynamic> json) {
    List<double>? coords;
    
    // Backend returns coordinates as direct array
    if (json['coordinates'] is List) {
      coords = (json['coordinates'] as List).cast<double>();
    }

    // Extract city from the JSON data
    String? cityValue = json['city'] as String?;
    
    // Backend returns 'address' field, map it to 'addressText'
    String? addressText = json['address'] as String? ?? json['addressText'] as String?;

    // If city is not provided, try to extract it from addressText
    if (cityValue == null && addressText != null) {
      // Try to extract city from address
      // This is a simple implementation - in a real app, you might need more sophisticated parsing
      final parts = addressText.split(',');
      if (parts.length >= 1) {
        // Assume the city is the first part of the address
        cityValue = parts[0].trim();
      }
    }

    return ProviderLocation(
      addressText: addressText,
      city: cityValue,
      coordinates: coords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressText': addressText,
      'city': city,
      'point': coordinates != null ? {'coordinates': coordinates} : null,
    };
  }
}

class ProviderContactInfo {
  final String? phone;
  // Add other contact fields if needed, e.g., secondaryEmail

  ProviderContactInfo({this.phone});

  factory ProviderContactInfo.fromJson(Map<String, dynamic> json) {
    return ProviderContactInfo(
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}

class Provider {
  final String? id;
  final String? fullName;
  final String? email; // Usually part of top-level, not contactInfo for login
  final String? companyName; // Can be same as fullName or separate
  final String? serviceType;
  final String? serviceDescription; // Changed from description for clarity
  final double? hourlyRate;
  final ProviderLocation? location;
  final ProviderContactInfo? contactInfo;
  final String? availabilityDetails;
  final String? profilePictureUrl; // Renamed from profileImage for consistency
  final double? averageRating;
  final int? totalRatings;
  
  // Admin management fields
  final String? verificationStatus; // 'pending', 'verified', 'rejected'
  final DateTime? joinedDate;
  final double? rating; // Overall rating
  final int? completedJobs;
  final DateTime? lastActive;
  final String? rejectionReason; // Reason for rejection if applicable
  
  // Advanced search fields
  final bool? isAvailable;
  final List<String>? serviceTags;
  final List<String>? serviceAreas;

  Provider({
    this.id,
    this.fullName,
    this.email,
    this.companyName,
    this.serviceType,
    this.serviceDescription,
    this.hourlyRate,
    this.location,
    this.contactInfo,
    this.availabilityDetails,
    this.profilePictureUrl,
    this.averageRating,
    this.totalRatings,
    this.verificationStatus,
    this.joinedDate,
    this.rating,
    this.completedJobs,
    this.lastActive,
    this.rejectionReason,
    this.isAvailable,
    this.serviceTags,
    this.serviceAreas,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Provider(
      id: json['_id'] as String? ?? json['id'] as String?, // Assuming your API returns _id
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      companyName: json['companyName'] as String?,
      serviceType: json['serviceType'] as String?,
      // Use serviceDescription, fallback to description if it exists from older model versions
      serviceDescription: json['serviceDescription'] as String? ??
          json['description'] as String?,
      hourlyRate: parseDouble(json['hourlyRate']),
      location: json['location'] != null
          ? ProviderLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      // Backend returns phoneNumber as direct field, not nested in contactInfo
      contactInfo: json['phoneNumber'] != null
          ? ProviderContactInfo(phone: json['phoneNumber'] as String?)
          : (json['contactInfo'] != null
              ? ProviderContactInfo.fromJson(
                  json['contactInfo'] as Map<String, dynamic>)
              : null),
      availabilityDetails: json['availabilityDetails'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String? ??
          json['profileImage'] as String?, // Fallback
      averageRating: parseDouble(json['averageRating']),
      totalRatings: parseInt(json['totalRatings']),
      
      // Admin management fields
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      joinedDate: parseDateTime(json['joinedDate']) ?? parseDateTime(json['createdAt']),
      rating: parseDouble(json['rating']) ?? parseDouble(json['averageRating']),
      completedJobs: parseInt(json['completedJobs']) ?? 0,
      lastActive: parseDateTime(json['lastActive']),
      rejectionReason: json['rejectionReason'] as String?,
      
      // Advanced search fields
      isAvailable: json['isAvailable'] as bool?,
      serviceTags: json['serviceTags'] != null 
          ? List<String>.from(json['serviceTags'])
          : null,
      serviceAreas: json['serviceAreas'] != null 
          ? List<String>.from(json['serviceAreas'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'companyName': companyName,
      'serviceType': serviceType,
      'serviceDescription': serviceDescription,
      'hourlyRate': hourlyRate,
      'location': location?.toJson(),
      'contactInfo': contactInfo?.toJson(),
      'availabilityDetails': availabilityDetails,
      'profilePictureUrl': profilePictureUrl,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'verificationStatus': verificationStatus,
      'joinedDate': joinedDate?.toIso8601String(),
      'rating': rating,
      'completedJobs': completedJobs,
      'lastActive': lastActive?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'isAvailable': isAvailable,
      'serviceTags': serviceTags,
      'serviceAreas': serviceAreas,
    };
  }

  // Create a copy of the provider with updated fields (useful for admin updates)
  Provider copyWith({
    String? id,
    String? fullName,
    String? email,
    String? companyName,
    String? serviceType,
    String? serviceDescription,
    double? hourlyRate,
    ProviderLocation? location,
    ProviderContactInfo? contactInfo,
    String? availabilityDetails,
    String? profilePictureUrl,
    double? averageRating,
    int? totalRatings,
    String? verificationStatus,
    DateTime? joinedDate,
    double? rating,
    int? completedJobs,
    DateTime? lastActive,
    String? rejectionReason,
  }) {
    return Provider(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      serviceType: serviceType ?? this.serviceType,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      location: location ?? this.location,
      contactInfo: contactInfo ?? this.contactInfo,
      availabilityDetails: availabilityDetails ?? this.availabilityDetails,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      joinedDate: joinedDate ?? this.joinedDate,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      lastActive: lastActive ?? this.lastActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() {
    return 'Provider{id: $id, fullName: $fullName, email: $email, serviceType: $serviceType, verificationStatus: $verificationStatus}';
  }
}
