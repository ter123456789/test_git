import 'dart:math' as math;

import '../entities/food_entry.dart';
import '../entities/ingredient.dart';
import '../entities/meal.dart';
import '../entities/nutrients.dart';

enum Nutrient {
  kcal('พลังงาน', 'kcal'),
  protein('โปรตีน', 'ก.'),
  carbs('คาร์บ', 'ก.'),
  fat('ไขมัน', 'ก.');

  const Nutrient(this.label, this.unit);

  final String label;
  final String unit;

  static const macros = [protein, carbs, fat];

  double of(Nutrients n) => switch (this) {
    kcal => n.kcal,
    protein => n.proteinG,
    carbs => n.carbsG,
    fat => n.fatG,
  };
}

enum BalanceStatus { low, ok, high }

/// สารอาหารหนึ่งตัวของมื้อ เทียบกับเป้า
class NutrientBalance {
  const NutrientBalance(this.nutrient, this.eaten, this.target);

  /// ห่างจากเป้าไม่เกินเท่านี้ถือว่าพอดี
  static const tolerance = 0.15;

  final Nutrient nutrient;
  final double eaten;
  final double target;

  /// บวกคือเกิน ลบคือขาด
  double get diff => eaten - target;

  double get ratio =>
      target == 0 ? (eaten == 0 ? 1 : double.infinity) : eaten / target;

  BalanceStatus get status {
    if (ratio < 1 - tolerance) return BalanceStatus.low;
    if (ratio > 1 + tolerance) return BalanceStatus.high;
    return BalanceStatus.ok;
  }
}

/// สิ่งที่กินในมื้อหนึ่งเทียบกับเป้าของมื้อนั้น
class MealBalance {
  const MealBalance({
    required this.meal,
    required this.eaten,
    required this.target,
  });

  final Meal meal;
  final Nutrients eaten;
  final Nutrients target;

  NutrientBalance of(Nutrient n) =>
      NutrientBalance(n, n.of(eaten), n.of(target));

  List<NutrientBalance> get items => [for (final n in Nutrient.values) of(n)];

  /// สารอาหารหลักที่ยังขาด เรียงจากขาดมากที่สุด (เทียบเป็นสัดส่วนของเป้า)
  List<NutrientBalance> get lacking => [
    for (final n in Nutrient.macros)
      if (of(n) case final b when b.status == BalanceStatus.low) b,
  ]..sort((a, b) => a.ratio.compareTo(b.ratio));

  List<NutrientBalance> get excess => [
    for (final n in Nutrient.values)
      if (of(n) case final b when b.status == BalanceStatus.high) b,
  ];
}

/// วัตถุดิบที่แนะนำให้กินเพิ่ม พร้อมปริมาณที่ทำให้สารอาหารที่ขาดถึงเป้า
class FoodSuggestion {
  const FoodSuggestion({
    required this.ingredient,
    required this.grams,
    required this.fills,
  });

  final Ingredient ingredient;
  final double grams;

  /// สารอาหารที่วัตถุดิบนี้ช่วยเติม
  final Nutrient fills;

  Nutrients get adds => ingredient.nutrientsFor(grams);
}

abstract final class MealPlanner {
  /// ปริมาณมากสุดที่ยังสมเหตุสมผลจะกินเพิ่มในมื้อเดียว
  static const maxSuggestedGrams = 400.0;

  /// เป้าของแต่ละมื้อ แบบปรับตามที่เหลือ:
  /// เอาเป้าทั้งวันลบสิ่งที่กินไปในมื้อก่อนหน้า แล้วแบ่งตามสัดส่วนของมื้อที่เหลือ
  /// ข้ามมื้อไหนไป มื้อถัดไปจะได้เป้าเพิ่ม กินเกินมื้อไหน มื้อถัดไปจะได้เป้าลดลง
  static Map<Meal, Nutrients> targets(
    Nutrients dayTarget,
    Iterable<FoodEntry> dayEntries,
  ) {
    final eaten = eatenByMeal(dayEntries);
    final result = <Meal, Nutrients>{};
    var remaining = dayTarget;
    var shareLeft = 1.0;
    for (final meal in Meal.values) {
      result[meal] = _atLeastZero(remaining).scale(meal.share / shareLeft);
      remaining -= eaten[meal]!;
      shareLeft -= meal.share;
    }
    return result;
  }

  static Map<Meal, Nutrients> eatenByMeal(Iterable<FoodEntry> dayEntries) => {
    for (final meal in Meal.values)
      meal: Nutrients.sum(
        dayEntries.where((e) => e.meal == meal).map((e) => e.nutrients),
      ),
  };

  static MealBalance balance(
    Meal meal,
    Nutrients dayTarget,
    Iterable<FoodEntry> dayEntries,
  ) => MealBalance(
    meal: meal,
    eaten: eatenByMeal(dayEntries)[meal]!,
    target: targets(dayTarget, dayEntries)[meal]!,
  );

  /// แนะนำวัตถุดิบจาก [items] เพื่อเติมสารอาหารที่ขาดมากที่สุดของมื้อ
  ///
  /// เลือกตัวที่เติมได้ถึงเป้าโดยทำให้ตัวอื่นเกินน้อยที่สุด ช่วยเติมตัวอื่นที่ขาดด้วย
  /// และไม่ต้องกินเยอะเกินไป
  static List<FoodSuggestion> suggest(
    MealBalance balance,
    Iterable<Ingredient> items, {
    int limit = 3,
  }) {
    final need = balance.lacking.firstOrNull;
    if (need == null) return const [];
    final shortfall = need.target - need.eaten;

    final scored = <(FoodSuggestion, double)>[];
    for (final item in items) {
      final per100g = need.nutrient.of(item.per100g);
      if (per100g <= 0) continue;
      // ปัดขึ้นทีละ 5 กรัม ให้เป็นตัวเลขที่ชั่งได้จริง
      final grams = math.max(10, (shortfall / per100g * 100 / 5).ceil() * 5);
      if (grams > maxSuggestedGrams) continue;

      final suggestion = FoodSuggestion(
        ingredient: item,
        grams: grams.toDouble(),
        fills: need.nutrient,
      );
      final after = balance.eaten + suggestion.adds;
      var penalty = 0.0;
      for (final n in Nutrient.values) {
        if (n == need.nutrient) continue;
        final ceiling = n.of(balance.target) * (1 + NutrientBalance.tolerance);
        final over = n.of(after) - ceiling;
        if (over > 0) penalty += over / math.max(n.of(balance.target), 1);
      }
      // ช่วยเติมตัวอื่นที่ขาดด้วยได้คะแนนดีขึ้น เช่น ขาดทั้งโปรตีนและไขมัน หมูดีกว่าน้ำมัน
      var bonus = 0.0;
      for (final other in balance.lacking.skip(1)) {
        final added = other.nutrient.of(suggestion.adds);
        bonus +=
            math.min(added, other.target - other.eaten) /
            math.max(other.target, 1);
      }
      // เสมอกันให้ตัวที่กินน้อยกว่าชนะ
      scored.add((suggestion, penalty - bonus + grams / 2000));
    }
    scored.sort((a, b) => a.$2.compareTo(b.$2));

    final names = <String>{};
    return [
      for (final (s, _) in scored)
        if (names.add(s.ingredient.name)) s,
    ].take(limit).toList();
  }

  static Nutrients _atLeastZero(Nutrients n) => Nutrients(
    kcal: math.max(0, n.kcal),
    proteinG: math.max(0, n.proteinG),
    carbsG: math.max(0, n.carbsG),
    fatG: math.max(0, n.fatG),
  );
}
