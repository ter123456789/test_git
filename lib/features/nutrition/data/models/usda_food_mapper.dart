import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';

/// แปลงรายการอาหารจากผลค้นหาของ USDA เป็น [Ingredient]
abstract final class UsdaFoodMapper {
  // nutrientId ของ FoodData Central
  static const _energyKcal = 1008;
  static const _energyAtwaterSpecific = 2048;
  static const _energyAtwaterGeneral = 2047;
  static const _protein = 1003;
  static const _fat = 1004;
  static const _carbsByDifference = 1005;
  static const _carbsBySummation = 1050;

  /// คืน null ถ้ารายการนั้นไม่มีข้อมูลโภชนาการพอให้ใช้
  static Ingredient? toIngredient(Map<String, dynamic> food) {
    final values = <int, double>{};
    for (final n in (food['foodNutrients'] as List? ?? const [])) {
      final m = n as Map<String, dynamic>;
      final id = m['nutrientId'];
      final value = m['value'];
      if (id is int && value is num) values[id] = value.toDouble();
    }

    final protein = values[_protein];
    final fat = values[_fat];
    final carbs = values[_carbsByDifference] ?? values[_carbsBySummation];
    // รายการชุด Foundation มักไม่มี 1008 แต่มีพลังงานแบบ Atwater แทน
    var kcal =
        values[_energyKcal] ??
        values[_energyAtwaterSpecific] ??
        values[_energyAtwaterGeneral];

    if (kcal == null && protein == null && fat == null && carbs == null) {
      return null;
    }
    // ไม่มีค่าพลังงาน แต่มีสารอาหารหลัก: ประมาณด้วย 4/4/9 kcal ต่อกรัม
    kcal ??= 4 * (protein ?? 0) + 4 * (carbs ?? 0) + 9 * (fat ?? 0);

    final description = food['description'] as String;
    return Ingredient(
      id: 'usda_${food['fdcId']}',
      name: description,
      nameEn: description,
      source: IngredientSource.usda,
      // บางรายการคาร์บ (by difference) ติดลบเล็กน้อยจากการปัดเศษ
      per100g: Nutrients(
        kcal: _nonNegative(kcal),
        proteinG: _nonNegative(protein),
        carbsG: _nonNegative(carbs),
        fatG: _nonNegative(fat),
      ),
    );
  }

  static double _nonNegative(double? v) => (v == null || v < 0) ? 0 : v;
}
