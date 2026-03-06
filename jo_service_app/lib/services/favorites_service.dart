import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritesService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'favorite_provider_ids';

  Future<Set<String>> getFavoriteProviderIds() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data.whereType<String>().toSet();
      }
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveFavoriteProviderIds(Set<String> ids) async {
    await _storage.write(key: _key, value: jsonEncode(ids.toList()));
  }
}

