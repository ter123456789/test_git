import 'package:equatable/equatable.dart';

import 'ingredient.dart';
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
  }) {
    if (grams <= 0) {
      throw ArgumentError.value(grams, 'grams', 'must be greater than 0');
    }
  }

  final String id;
  final Ingredient ingredient;
  final double grams;
  final DateTime eatenAt;

  Nutrients get nutrients => ingredient.nutrientsFor(grams);

  @override
  List<Object?> get props => [id, ingredient, grams, eatenAt];
}
