import '../../../../core/utils/thai_text.dart';
import '../../domain/entities/ingredient.dart';

/// วัตถุดิบที่หาซื้อง่ายในไทย ใช้คัดของที่จะแนะนำให้กินเพิ่ม
abstract final class ThaiAvailability {
  /// วัตถุดิบพื้นฐานที่มีขายทั่วไปตามตลาด ร้านสะดวกซื้อ หรือร้านอาหารตามสั่ง
  ///
  /// ใช้รายการที่อนุญาตแทนรายการห้าม วัตถุดิบที่เพิ่มเข้า builtin ภายหลัง
  /// จะไม่ถูกแนะนำจนกว่าจะใส่ไว้ที่นี่ ที่ไม่อยู่ในรายการ:
  /// - หายากหรือราคาสูง: เนื้อวัวบด ปลาแซลมอน อะโวคาโด
  /// - ไม่ควรแนะนำให้กินเปล่า ๆ: น้ำมันพืช น้ำตาลทราย
  static const _builtinIds = {
    'rice_white',
    'rice_brown',
    'rice_sticky',
    'rice_noodle',
    'bread_wholewheat',
    'potato',
    'chicken_breast',
    'chicken_thigh',
    'egg',
    'pork_tenderloin',
    'pork_belly',
    'pork_ground',
    'shrimp',
    'tilapia',
    'tofu_firm',
    'milk_whole',
    'broccoli',
    'morning_glory',
    'chinese_kale',
    'carrot',
    'tomato',
    'banana',
    'apple',
    'guava',
    'peanut',
  };

  static bool isEasyToFind(Ingredient i) => switch (i.source) {
    IngredientSource.builtin => _builtinIds.contains(i.id),
    // user เพิ่มเอง แปลว่าหามากินได้อยู่แล้ว
    IngredientSource.custom => true,
    // ของจาก USDA นับเฉพาะที่ user ตั้งชื่อไทยให้ ชื่ออังกฤษล้วนมักเป็นของนอก
    IngredientSource.usda => ThaiText.hasThai(i.name),
    // สแกนจากของที่ซื้อมาจริง
    IngredientSource.openFoodFacts => true,
  };
}
