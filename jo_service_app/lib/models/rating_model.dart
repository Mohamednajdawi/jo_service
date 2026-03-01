class Rating {
  final String? id;
  final String bookingId;
  final String providerId;
  final String userId;
  final double punctuality;
  final double workQuality;
  final double speedAndEfficiency;
  final double cleanliness;
  final double overallRating;
  final String? review;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rating({
    this.id,
    required this.bookingId,
    required this.providerId,
    required this.userId,
    required this.punctuality,
    required this.workQuality,
    required this.speedAndEfficiency,
    required this.cleanliness,
    required this.overallRating,
    this.review,
    this.createdAt,
    this.updatedAt,
  });

  // Calculate overall rating from individual criteria
  static double calculateOverallRating({
    required double punctuality,
    required double workQuality,
    required double speedAndEfficiency,
    required double cleanliness,
  }) {
    return (punctuality + workQuality + speedAndEfficiency + cleanliness) / 4.0;
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
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

    return Rating(
      id: json['_id'] as String? ?? json['id'] as String?,
      bookingId: json['bookingId'] as String,
      providerId: json['providerId'] as String,
      userId: json['userId'] as String,
      punctuality: parseDouble(json['punctuality']),
      workQuality: parseDouble(json['workQuality']),
      speedAndEfficiency: parseDouble(json['speedAndEfficiency']),
      cleanliness: parseDouble(json['cleanliness']),
      overallRating: parseDouble(json['overallRating']),
      review: json['review'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'providerId': providerId,
      'userId': userId,
      'punctuality': punctuality,
      'workQuality': workQuality,
      'speedAndEfficiency': speedAndEfficiency,
      'cleanliness': cleanliness,
      'overallRating': overallRating,
      'review': review,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Rating copyWith({
    String? id,
    String? bookingId,
    String? providerId,
    String? userId,
    double? punctuality,
    double? workQuality,
    double? speedAndEfficiency,
    double? cleanliness,
    double? overallRating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      providerId: providerId ?? this.providerId,
      userId: userId ?? this.userId,
      punctuality: punctuality ?? this.punctuality,
      workQuality: workQuality ?? this.workQuality,
      speedAndEfficiency: speedAndEfficiency ?? this.speedAndEfficiency,
      cleanliness: cleanliness ?? this.cleanliness,
      overallRating: overallRating ?? this.overallRating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Rating{id: $id, bookingId: $bookingId, providerId: $providerId, overallRating: $overallRating}';
  }
}

// Model for displaying rating statistics
class ProviderRatingStats {
  final double averagePunctuality;
  final double averageWorkQuality;
  final double averageSpeedAndEfficiency;
  final double averageCleanliness;
  final double overallAverageRating;
  final int totalRatings;
  final List<Rating> recentRatings;

  ProviderRatingStats({
    required this.averagePunctuality,
    required this.averageWorkQuality,
    required this.averageSpeedAndEfficiency,
    required this.averageCleanliness,
    required this.overallAverageRating,
    required this.totalRatings,
    required this.recentRatings,
  });

  factory ProviderRatingStats.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    List<Rating> parseRatings(dynamic ratingsJson) {
      if (ratingsJson is List) {
        return ratingsJson
            .map((rating) => Rating.fromJson(rating as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return ProviderRatingStats(
      averagePunctuality: parseDouble(json['averagePunctuality']),
      averageWorkQuality: parseDouble(json['averageWorkQuality']),
      averageSpeedAndEfficiency: parseDouble(json['averageSpeedAndEfficiency']),
      averageCleanliness: parseDouble(json['averageCleanliness']),
      overallAverageRating: parseDouble(json['overallAverageRating']),
      totalRatings: parseInt(json['totalRatings']),
      recentRatings: parseRatings(json['recentRatings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePunctuality': averagePunctuality,
      'averageWorkQuality': averageWorkQuality,
      'averageSpeedAndEfficiency': averageSpeedAndEfficiency,
      'averageCleanliness': averageCleanliness,
      'overallAverageRating': overallAverageRating,
      'totalRatings': totalRatings,
      'recentRatings': recentRatings.map((rating) => rating.toJson()).toList(),
    };
  }
}
