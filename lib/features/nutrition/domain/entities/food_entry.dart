import 'package:equatable/equatable.dart';

import 'ingredient.dart';
import 'meal.dart';
import 'nutrients.dart';

/// วัตถุดิบหนึ่งรายการที่ user กินไป
///
/// เก็บสำเนาของ [ingredient] ไว้ทั้งก้อน เพื่อให้ประวัติไม่เปลี่ยน
/// แม้ภายหลังจะแก้ไขหรือลบวัตถุดิบนั้นออกจากรายการ
class FoodEntry extends Equatable {
  FoodEntry({
    required this.id,
    required this.ingredient,
    required this.grams,
    required this.eatenAt,
    Meal? meal,
  }) : meal = meal ?? Meal.fromTime(eatenAt) {
    if (grams <= 0) {
      throw ArgumentError.value(grams, 'grams', 'must be greater than 0');
    }
  }

  final String id;
  final Ingredient ingredient;
  final double grams;
  final DateTime eatenAt;

  /// มื้อที่ user เลือก ถ้าไม่ระบุจะเดาจากเวลาที่กิน
  final Meal meal;

  Nutrients get nutrients => ingredient.nutrientsFor(grams);

  @override
  List<Object?> get props => [id, ingredient, grams, eatenAt, meal];
}
