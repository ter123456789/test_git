import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileLocalDataSource {
  const ProfileLocalDataSource(this._prefs);

  static const _key = 'user_profile';

  final SharedPreferences _prefs;

  Map<String, dynamic>? read() {
    final raw = _prefs.getString(_key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> write(Map<String, dynamic> json) =>
      _prefs.setString(_key, jsonEncode(json));

  Future<void> clear() => _prefs.remove(_key);
}
