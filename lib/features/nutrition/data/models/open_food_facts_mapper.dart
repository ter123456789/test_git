import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';

/// แปลงสินค้าจาก Open Food Facts เป็น [Ingredient]
abstract final class OpenFoodFactsMapper {
  static const _kjPerKcal = 4.184;

  /// คืน null ถ้าสินค้านั้นไม่มีข้อมูลโภชนาการพอให้ใช้
  static Ingredient? toIngredient(
    String barcode,
    Map<String, dynamic> product,
  ) {
    final n = product['nutriments'] as Map<String, dynamic>? ?? const {};
    final protein = _number(n['proteins_100g']);
    final carbs = _number(n['carbohydrates_100g']);
    final fat = _number(n['fat_100g']);
    // ฉลากบางตัวกรอกไว้แค่กิโลจูล
    final kj = _number(n['energy_100g']);
    var kcal =
        _number(n['energy-kcal_100g']) ?? (kj == null ? null : kj / _kjPerKcal);

    if (kcal == null && protein == null && fat == null && carbs == null) {
      return null;
    }
    // ไม่มีค่าพลังงาน แต่มีสารอาหารหลัก: ประมาณด้วย 4/4/9 kcal ต่อกรัม
    kcal ??= 4 * (protein ?? 0) + 4 * (carbs ?? 0) + 9 * (fat ?? 0);

    final nameEn = _text(product['product_name_en']);
    final name =
        _text(product['product_name_th']) ??
        _text(product['product_name']) ??
        nameEn ??
        'สินค้า $barcode';
    return Ingredient(
      id: 'off_$barcode',
      name: name,
      nameEn: nameEn,
      source: IngredientSource.openFoodFacts,
      barcode: barcode,
      per100g: Nutrients(
        kcal: _nonNegative(kcal),
        proteinG: _nonNegative(protein),
        carbsG: _nonNegative(carbs),
        fatG: _nonNegative(fat),
      ),
    );
  }

  /// ค่าใน nutriments มีทั้งตัวเลขและข้อความ
  static double? _number(Object? v) => switch (v) {
    num() => v.toDouble(),
    String() => double.tryParse(v),
    _ => null,
  };

  static String? _text(Object? v) {
    final s = (v as String?)?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  static double _nonNegative(double? v) => (v == null || v < 0) ? 0 : v;
}
