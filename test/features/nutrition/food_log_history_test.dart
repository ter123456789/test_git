import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/core/providers/shared_preferences_provider.dart';
import 'package:test_git/features/nutrition/data/models/nutrition_models.dart';
import 'package:test_git/features/nutrition/domain/entities/food_entry.dart';
import 'package:test_git/features/nutrition/domain/entities/food_log_stats.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/nutrients.dart';
import 'package:test_git/features/nutrition/presentation/providers/nutrition_providers.dart';

void main() {
  const rice = Ingredient(
    id: 'rice',
    name: 'ข้าวสวย',
    per100g: Nutrients(kcal: 130, proteinG: 2.7, carbsG: 28, fatG: 0.3),
  );

  Future<ProviderContainer> containerWith(List<FoodEntry> entries) async {
    SharedPreferences.setMockInitialValues({
      'food_log': jsonEncode(entries.map(NutritionModels.entryToJson).toList()),
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(foodLogProvider.future);
    return container;
  }

  test('รวมพลังงานรายวันย้อนหลัง วันที่ไม่ได้บันทึกเป็น 0', () async {
    final c = await containerWith([
      FoodEntry(
        id: 'a',
        ingredient: rice,
        grams: 100,
        eatenAt: DateTime(2026, 10, 1, 8),
      ),
      FoodEntry(
        id: 'b',
        ingredient: rice,
        grams: 200,
        eatenAt: DateTime(2026, 10, 1, 19),
      ),
      FoodEntry(
        id: 'c',
        ingredient: rice,
        grams: 100,
        eatenAt: DateTime(2026, 9, 30, 12),
      ),
    ]);

    final log = c.read(foodLogProvider).requireValue;
    final days = log.dailyKcal(end: DateTime(2026, 10, 2), days: 3);
    expect(days.map((d) => d.$1), [
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
    ]);
    expect(days.map((d) => d.$2), [130, 390, 0]);
    expect(log.loggedDays, {DateTime(2026, 9, 30), DateTime(2026, 10, 1)});
    expect(log.entriesOn(DateTime(2026, 10, 1)).map((e) => e.id), ['a', 'b']);
  });

  test('บันทึกย้อนหลังลงวันที่เลือก', () async {
    final c = await containerWith([]);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final day = DateTime(yesterday.year, yesterday.month, yesterday.day);

    await c.read(foodLogProvider.notifier).add(rice, 100, day: day);

    final log = c.read(foodLogProvider).requireValue;
    expect(log.entriesOn(day), hasLength(1));
    expect(log.totalsOn(day).kcal, 130);
  });
}
