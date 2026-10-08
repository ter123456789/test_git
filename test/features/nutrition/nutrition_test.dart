import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/features/nutrition/data/datasources/builtin_ingredients.dart';
import 'package:test_git/features/nutrition/data/datasources/nutrition_local_data_source.dart';
import 'package:test_git/features/nutrition/data/datasources/usda_remote_data_source.dart';
import 'package:test_git/features/nutrition/data/repositories/food_log_repository_impl.dart';
import 'package:test_git/features/nutrition/data/repositories/ingredient_repository_impl.dart';
import 'package:test_git/features/nutrition/domain/entities/food_entry.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/nutrients.dart';

void main() {
  const chicken = Ingredient(
    id: 'chicken',
    name: 'อกไก่',
    per100g: Nutrients(kcal: 120, proteinG: 22.5, carbsG: 0, fatG: 2.6),
  );

  group('entities', () {
    test('คำนวณโภชนาการตามน้ำหนักที่กิน', () {
      final n = chicken.nutrientsFor(150);
      expect(n.kcal, closeTo(180, 0.001));
      expect(n.proteinG, closeTo(33.75, 0.001));
    });

    test('รวมค่าโภชนาการหลายรายการ', () {
      final total = Nutrients.sum([
        chicken.nutrientsFor(100),
        chicken.nutrientsFor(50),
      ]);
      expect(total.kcal, closeTo(180, 0.001));
    });

    test('FoodEntry ไม่รับน้ำหนัก 0 หรือติดลบ', () {
      expect(
        () => FoodEntry(
          id: '1',
          ingredient: chicken,
          grams: 0,
          eatenAt: DateTime(2026),
        ),
        throwsArgumentError,
      );
    });
  });

  group('repositories', () {
    late NutritionLocalDataSource local;
    final offlineUsda = UsdaRemoteDataSource(
      client: MockClient((_) async => http.Response('', 500)),
      apiKey: 'test',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = NutritionLocalDataSource(await SharedPreferences.getInstance());
    });

    test('วัตถุดิบที่เพิ่มเองถูกเก็บและรวมกับฐานข้อมูลในแอป', () async {
      final repo = IngredientRepositoryImpl(local, offlineUsda);
      const custom = Ingredient(
        id: 'custom_1',
        name: 'น้ำพริกหนุ่ม',
        per100g: Nutrients(kcal: 90, proteinG: 2, carbsG: 10, fatG: 5),
        source: IngredientSource.custom,
      );

      await repo.save(custom);
      await repo.save(custom); // id ซ้ำต้องไม่ถูกเก็บซ้ำ
      final all = await IngredientRepositoryImpl(local, offlineUsda).getAll();

      expect(all.length, builtinIngredients.length + 1);
      expect(all.last, custom);
    });

    test('อ่านข้อมูลรุ่นแรกที่เก็บเป็น isCustom ได้', () async {
      SharedPreferences.setMockInitialValues({
        'custom_ingredients':
            '[{"id":"c1","name":"x","isCustom":true,'
            '"per100g":{"kcal":1,"proteinG":0,"carbsG":0,"fatG":0}}]',
      });
      local = NutritionLocalDataSource(await SharedPreferences.getInstance());

      final all = await IngredientRepositoryImpl(local, offlineUsda).getAll();
      expect(all.last.source, IngredientSource.custom);
    });

    test('บันทึกการกินกรองตามวัน และลบได้', () async {
      final repo = FoodLogRepositoryImpl(local);
      final today = DateTime(2026, 10, 7, 12);
      await repo.add(
        FoodEntry(id: 'a', ingredient: chicken, grams: 100, eatenAt: today),
      );
      await repo.add(
        FoodEntry(
          id: 'b',
          ingredient: chicken,
          grams: 50,
          eatenAt: DateTime(2026, 10, 6, 20),
        ),
      );

      final entries = await repo.getEntriesOn(DateTime(2026, 10, 7));
      expect(entries.map((e) => e.id), ['a']);
      expect(entries.single.eatenAt, today);

      await repo.remove('a');
      expect(await repo.getEntriesOn(DateTime(2026, 10, 7)), isEmpty);
    });
  });
}
