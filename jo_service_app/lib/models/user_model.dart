class User {
  final String? id;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.profilePictureUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      profilePictureUrl: json['profilePictureUrl'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
