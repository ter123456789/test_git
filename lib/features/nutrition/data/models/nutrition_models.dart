import '../../domain/entities/food_entry.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';

/// แปลง entity ของ nutrition กับ JSON ที่เก็บในเครื่อง
abstract final class NutritionModels {
  static Map<String, dynamic> nutrientsToJson(Nutrients n) => {
    'kcal': n.kcal,
    'proteinG': n.proteinG,
    'carbsG': n.carbsG,
    'fatG': n.fatG,
  };

  static Nutrients nutrientsFromJson(Map<String, dynamic> json) => Nutrients(
    kcal: (json['kcal'] as num).toDouble(),
    proteinG: (json['proteinG'] as num).toDouble(),
    carbsG: (json['carbsG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
  );

  static Map<String, dynamic> ingredientToJson(Ingredient i) => {
    'id': i.id,
    'name': i.name,
    'nameEn': i.nameEn,
    'per100g': nutrientsToJson(i.per100g),
    'source': i.source.name,
  };

  static Ingredient ingredientFromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'] as String,
    name: json['name'] as String,
    nameEn: json['nameEn'] as String?,
    per100g: nutrientsFromJson(json['per100g'] as Map<String, dynamic>),
    source: _sourceFromJson(json),
  );

  /// ข้อมูลรุ่นแรกเก็บเป็น `isCustom` แทน `source`
  static IngredientSource _sourceFromJson(Map<String, dynamic> json) {
    final source = json['source'] as String?;
    if (source != null) return IngredientSource.values.byName(source);
    return json['isCustom'] == true
        ? IngredientSource.custom
        : IngredientSource.builtin;
  }

  static Map<String, dynamic> entryToJson(FoodEntry e) => {
    'id': e.id,
    'ingredient': ingredientToJson(e.ingredient),
    'grams': e.grams,
    'eatenAt': e.eatenAt.toIso8601String(),
  };

  static FoodEntry entryFromJson(Map<String, dynamic> json) => FoodEntry(
    id: json['id'] as String,
    ingredient: ingredientFromJson(json['ingredient'] as Map<String, dynamic>),
    grams: (json['grams'] as num).toDouble(),
    eatenAt: DateTime.parse(json['eatenAt'] as String),
  );
}
