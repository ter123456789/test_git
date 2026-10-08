import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NutritionLocalDataSource {
  const NutritionLocalDataSource(this._prefs);

  /// วัตถุดิบที่ user เพิ่มเองและที่เลือกมาจาก USDA
  static const _savedIngredientsKey = 'custom_ingredients';
  static const _foodLogKey = 'food_log';

  final SharedPreferences _prefs;

  List<Map<String, dynamic>> readSavedIngredients() =>
      _readList(_savedIngredientsKey);

  Future<void> writeSavedIngredients(List<Map<String, dynamic>> items) =>
      _writeList(_savedIngredientsKey, items);

  List<Map<String, dynamic>> readFoodLog() => _readList(_foodLogKey);

  Future<void> writeFoodLog(List<Map<String, dynamic>> items) =>
      _writeList(_foodLogKey, items);

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items));
}
