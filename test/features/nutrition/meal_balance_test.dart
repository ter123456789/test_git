import 'package:flutter_test/flutter_test.dart';
import 'package:test_git/features/nutrition/data/datasources/builtin_ingredients.dart';
import 'package:test_git/features/nutrition/data/datasources/thai_availability.dart';
import 'package:test_git/features/nutrition/data/models/nutrition_models.dart';
import 'package:test_git/features/nutrition/domain/entities/food_entry.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/meal.dart';
import 'package:test_git/features/nutrition/domain/entities/nutrients.dart';
import 'package:test_git/features/nutrition/domain/usecases/meal_balance.dart';

void main() {
  // 2000 kcal แบ่ง P20/C50/F30 = 100 / 250 / 66.7 ก.
  const day = Nutrients(kcal: 2000, proteinG: 100, carbsG: 250, fatG: 66.7);
  const rice = Ingredient(
    id: 'rice',
    name: 'ข้าวสวย',
    per100g: Nutrients(kcal: 130, proteinG: 2.7, carbsG: 28, fatG: 0.3),
  );

  FoodEntry entry(Meal meal, double grams, {Ingredient food = rice}) =>
      FoodEntry(
        id: '${meal.name}$grams',
        ingredient: food,
        grams: grams,
        eatenAt: DateTime(2026, 10, 8, 12),
        meal: meal,
      );

  group('Meal', () {
    test('เดามื้อจากเวลา', () {
      expect(Meal.fromTime(DateTime(2026, 1, 1, 7)), Meal.breakfast);
      expect(Meal.fromTime(DateTime(2026, 1, 1, 12)), Meal.lunch);
      expect(Meal.fromTime(DateTime(2026, 1, 1, 16)), Meal.snack);
      expect(Meal.fromTime(DateTime(2026, 1, 1, 19)), Meal.dinner);
      expect(Meal.fromTime(DateTime(2026, 1, 1, 23)), Meal.snack);
    });

    test('สัดส่วนทุกมื้อรวมกันได้ 1', () {
      expect(
        Meal.values.fold<double>(0, (s, m) => s + m.share),
        closeTo(1, 1e-9),
      );
    });

    test('JSON เก็บมื้อไว้ ส่วนข้อมูลเก่าที่ไม่มีมื้อเดาจากเวลา', () {
      final e = entry(Meal.snack, 100);
      final json = NutritionModels.entryToJson(e);
      expect(NutritionModels.entryFromJson(json).meal, Meal.snack);

      final legacy = Map<String, dynamic>.of(json)..remove('meal');
      expect(NutritionModels.entryFromJson(legacy).meal, Meal.lunch);
    });
  });

  group('MealPlanner.targets', () {
    // ข้าว 100/130 × 500 ก. = 500 kcal พอดีเป้ามื้อเช้า
    final onTrack = [entry(Meal.breakfast, 50000 / 130)];

    test('มื้อเช้ากินตามเป้าพอดี มื้อกลางวันได้ตามสัดส่วนปกติ', () {
      expect(
        MealPlanner.targets(day, const [])[Meal.breakfast]!.kcal,
        closeTo(500, 1e-6),
      );
      final t = MealPlanner.targets(day, onTrack);
      expect(t[Meal.lunch]!.kcal, closeTo(700, 1e-6));
    });

    test('ข้ามมื้อเช้า มื้อกลางวันได้เป้าเพิ่ม', () {
      final t = MealPlanner.targets(day, onTrack);
      final lunchOnly = MealPlanner.targets(day, [entry(Meal.lunch, 100)]);
      // มื้อเช้าไม่ได้กิน: กลางวัน = 2000 × 0.35 / 0.75
      expect(lunchOnly[Meal.lunch]!.kcal, closeTo(2000 * 0.35 / 0.75, 1e-6));
      expect(lunchOnly[Meal.lunch]!.kcal, greaterThan(t[Meal.lunch]!.kcal));
    });

    test('มื้อก่อนหน้ากินเกิน มื้อถัดไปได้เป้าลดลง และไม่ติดลบ', () {
      final heavy = MealPlanner.targets(day, [entry(Meal.breakfast, 1000)]);
      // กินไป 1300 kcal เหลือ 700 แบ่งให้ กลางวัน 0.35/0.75
      expect(heavy[Meal.lunch]!.kcal, closeTo(700 * 0.35 / 0.75, 1e-6));

      final huge = MealPlanner.targets(day, [entry(Meal.breakfast, 3000)]);
      expect(huge[Meal.dinner]!.kcal, 0);
      expect(huge[Meal.dinner]!.carbsG, 0);
    });
  });

  group('MealBalance', () {
    test('บอกว่าขาดหรือเกินอะไร โดยมีช่วงพอดี ±15%', () {
      // มื้อกลางวัน ข้าว 250 ก. = 325 kcal, P 6.75, C 70, F 0.75
      final b = MealPlanner.balance(Meal.lunch, day, [
        entry(Meal.breakfast, 380),
        entry(Meal.lunch, 250),
      ]);
      expect(b.lacking.map((x) => x.nutrient), [
        Nutrient.fat,
        Nutrient.protein,
      ]);
      expect(b.of(Nutrient.protein).status, BalanceStatus.low);
      expect(b.excess, isEmpty);
    });

    test('สมดุลดีเมื่ออยู่ในช่วงพอดีทุกตัว', () {
      final b = MealBalance(
        meal: Meal.lunch,
        eaten: const Nutrients(kcal: 650, proteinG: 33, carbsG: 90, fatG: 21),
        target: const Nutrients(kcal: 700, proteinG: 35, carbsG: 87, fatG: 23),
      );
      expect(b.lacking, isEmpty);
      expect(b.excess, isEmpty);
    });
  });

  group('MealPlanner.suggest', () {
    test('ขาดโปรตีน แนะนำของโปรตีนสูงพร้อมปริมาณที่เติมถึงเป้า', () {
      final b = MealBalance(
        meal: Meal.lunch,
        eaten: const Nutrients(kcal: 450, proteinG: 10, carbsG: 85, fatG: 12),
        target: const Nutrients(kcal: 700, proteinG: 35, carbsG: 87, fatG: 23),
      );
      final s = MealPlanner.suggest(b, builtinIngredients);
      expect(s, isNotEmpty);
      expect(s.length, lessThanOrEqualTo(3));
      for (final x in s) {
        expect(x.fills, Nutrient.protein);
        expect(x.grams, lessThanOrEqualTo(MealPlanner.maxSuggestedGrams));
        expect(x.grams % 5, 0);
        // เติมแล้วโปรตีนถึงเป้า
        expect(x.adds.proteinG, greaterThanOrEqualTo(25));
        // คาร์บเกือบเต็มแล้ว ไม่ควรแนะนำของที่คาร์บเยอะ
        expect(85 + x.adds.carbsG, lessThanOrEqualTo(87 * 1.15));
      }
      // ข้าวโปรตีนต่ำเกินไป ต้องกินเกิน 400 ก. จึงไม่ถูกแนะนำ
      expect(s.map((x) => x.ingredient.id), isNot(contains('rice_white')));
    });

    test('ไม่ขาดอะไร ไม่ต้องแนะนำ', () {
      final b = MealBalance(
        meal: Meal.lunch,
        eaten: const Nutrients(kcal: 700, proteinG: 35, carbsG: 87, fatG: 23),
        target: const Nutrients(kcal: 700, proteinG: 35, carbsG: 87, fatG: 23),
      );
      expect(MealPlanner.suggest(b, builtinIngredients), isEmpty);
    });
  });

  group('ThaiAvailability', () {
    test('ตัดของหายาก/ราคาสูง และของที่ไม่ควรกินเปล่า ๆ ออก', () {
      final ids = builtinIngredients
          .where(ThaiAvailability.isEasyToFind)
          .map((i) => i.id)
          .toSet();
      expect(
        ids,
        containsAll([
          'chicken_breast',
          'egg',
          'pork_belly',
          'tilapia',
          'chicken_thigh',
          'pork_ground',
          'rice_sticky',
          'guava',
          'chinese_kale',
        ]),
      );
      for (final id in [
        'salmon',
        'beef_ground',
        'avocado',
        'vegetable_oil',
        'sugar',
      ]) {
        expect(ids, isNot(contains(id)));
      }
    });

    test('ของที่ user เพิ่มเองนับเสมอ ของจาก USDA นับเมื่อตั้งชื่อไทย', () {
      const per100g = Nutrients(kcal: 100, proteinG: 20, carbsG: 0, fatG: 2);
      const custom = Ingredient(
        id: 'c',
        name: 'Protein bar',
        per100g: per100g,
        source: IngredientSource.custom,
      );
      const usda = Ingredient(
        id: 'u',
        name: 'Fish, tilapia, raw',
        per100g: per100g,
        source: IngredientSource.usda,
      );
      expect(ThaiAvailability.isEasyToFind(custom), isTrue);
      expect(ThaiAvailability.isEasyToFind(usda), isFalse);
      expect(ThaiAvailability.isEasyToFind(usda.withName('ปลานิล')), isTrue);
    });

    test('id วัตถุดิบไม่ซ้ำกัน', () {
      final ids = builtinIngredients.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('มื้อที่มีแต่ข้าว แนะนำของไทยแทนแซลมอนและเนื้อวัวบด', () {
      final b = MealPlanner.balance(Meal.lunch, day, [entry(Meal.lunch, 250)]);
      final s = MealPlanner.suggest(
        b,
        builtinIngredients.where(ThaiAvailability.isEasyToFind),
      );
      expect(s, isNotEmpty);
      expect(
        s.map((x) => x.ingredient.id),
        everyElement(isNot(anyOf('salmon', 'beef_ground'))),
      );
    });
  });
}
