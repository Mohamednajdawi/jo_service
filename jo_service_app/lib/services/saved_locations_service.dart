import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedLocation {
  final String id;
  final String label;
  final String address;

  SavedLocation({
    required this.id,
    required this.label,
    required this.address,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
    };
  }
}

class SavedLocationsService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'user_saved_locations';

  Future<List<SavedLocation>> getLocations() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => SavedLocation.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocations(List<SavedLocation> locations) async {
    final encoded =
        jsonEncode(locations.map((location) => location.toJson()).toList());
    await _storage.write(key: _key, value: encoded);
  }
}

