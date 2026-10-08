import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';

/// ฐานข้อมูลวัตถุดิบพื้นฐาน ค่าต่อ 100 กรัม
///
/// ค่าโดยประมาณ อ้างอิงจาก USDA FoodData Central
/// (ข้าว เส้น และธัญพืชเป็นค่าหลังหุงสุก ส่วนเนื้อสัตว์และผักเป็นค่าดิบ)
const builtinIngredients = <Ingredient>[
  Ingredient(
    id: 'rice_white',
    name: 'ข้าวสวย',
    nameEn: 'white rice, cooked',
    per100g: Nutrients(kcal: 130, proteinG: 2.7, carbsG: 28.2, fatG: 0.3),
  ),
  Ingredient(
    id: 'rice_brown',
    name: 'ข้าวกล้อง (สุก)',
    nameEn: 'brown rice, cooked',
    per100g: Nutrients(kcal: 123, proteinG: 2.7, carbsG: 25.6, fatG: 1.0),
  ),
  Ingredient(
    id: 'rice_sticky',
    name: 'ข้าวเหนียว (นึ่ง)',
    nameEn: 'glutinous rice, cooked',
    per100g: Nutrients(kcal: 97, proteinG: 2.0, carbsG: 21.1, fatG: 0.2),
  ),
  Ingredient(
    id: 'rice_noodle',
    name: 'เส้นก๋วยเตี๋ยว (สุก)',
    nameEn: 'rice noodles, cooked',
    per100g: Nutrients(kcal: 108, proteinG: 1.8, carbsG: 24.0, fatG: 0.2),
  ),
  Ingredient(
    id: 'bread_wholewheat',
    name: 'ขนมปังโฮลวีท',
    nameEn: 'whole wheat bread',
    per100g: Nutrients(kcal: 247, proteinG: 13.0, carbsG: 41.0, fatG: 3.4),
  ),
  Ingredient(
    id: 'potato',
    name: 'มันฝรั่ง',
    nameEn: 'potato, raw',
    per100g: Nutrients(kcal: 77, proteinG: 2.0, carbsG: 17.0, fatG: 0.1),
  ),
  Ingredient(
    id: 'chicken_breast',
    name: 'อกไก่ (ไม่มีหนัง)',
    nameEn: 'chicken breast, skinless, raw',
    per100g: Nutrients(kcal: 120, proteinG: 22.5, carbsG: 0, fatG: 2.6),
  ),
  Ingredient(
    id: 'chicken_thigh',
    name: 'สะโพกไก่ (ไม่มีหนัง)',
    nameEn: 'chicken thigh, meat only, raw',
    per100g: Nutrients(kcal: 121, proteinG: 19.7, carbsG: 0, fatG: 4.1),
  ),
  Ingredient(
    id: 'egg',
    name: 'ไข่ไก่',
    nameEn: 'egg, whole, raw',
    per100g: Nutrients(kcal: 143, proteinG: 12.6, carbsG: 0.7, fatG: 9.5),
  ),
  Ingredient(
    id: 'pork_tenderloin',
    name: 'หมูสันใน',
    nameEn: 'pork tenderloin, raw',
    per100g: Nutrients(kcal: 120, proteinG: 21.0, carbsG: 0, fatG: 3.5),
  ),
  Ingredient(
    id: 'pork_belly',
    name: 'หมูสามชั้น',
    nameEn: 'pork belly, raw',
    per100g: Nutrients(kcal: 518, proteinG: 9.3, carbsG: 0, fatG: 53.0),
  ),
  Ingredient(
    id: 'pork_ground',
    name: 'หมูสับ',
    nameEn: 'ground pork, raw',
    per100g: Nutrients(kcal: 263, proteinG: 16.9, carbsG: 0, fatG: 21.2),
  ),
  Ingredient(
    id: 'beef_ground',
    name: 'เนื้อวัวบด (ไขมัน 15%)',
    nameEn: 'ground beef 85% lean, raw',
    per100g: Nutrients(kcal: 215, proteinG: 18.6, carbsG: 0, fatG: 15.0),
  ),
  Ingredient(
    id: 'salmon',
    name: 'ปลาแซลมอน',
    nameEn: 'salmon, atlantic, raw',
    per100g: Nutrients(kcal: 208, proteinG: 20.0, carbsG: 0, fatG: 13.0),
  ),
  Ingredient(
    id: 'tilapia',
    name: 'ปลานิล',
    nameEn: 'tilapia, raw',
    per100g: Nutrients(kcal: 96, proteinG: 20.1, carbsG: 0, fatG: 1.7),
  ),
  Ingredient(
    id: 'shrimp',
    name: 'กุ้ง',
    nameEn: 'shrimp, raw',
    per100g: Nutrients(kcal: 85, proteinG: 20.1, carbsG: 0, fatG: 0.5),
  ),
  Ingredient(
    id: 'tofu_firm',
    name: 'เต้าหู้แข็ง',
    nameEn: 'tofu, firm',
    per100g: Nutrients(kcal: 144, proteinG: 17.3, carbsG: 2.8, fatG: 8.7),
  ),
  Ingredient(
    id: 'milk_whole',
    name: 'นมวัว (ไขมันเต็ม)',
    nameEn: 'milk, whole',
    per100g: Nutrients(kcal: 61, proteinG: 3.2, carbsG: 4.8, fatG: 3.3),
  ),
  Ingredient(
    id: 'broccoli',
    name: 'บรอกโคลี',
    nameEn: 'broccoli, raw',
    per100g: Nutrients(kcal: 34, proteinG: 2.8, carbsG: 6.6, fatG: 0.4),
  ),
  Ingredient(
    id: 'morning_glory',
    name: 'ผักบุ้ง',
    nameEn: 'water spinach, raw',
    per100g: Nutrients(kcal: 19, proteinG: 2.6, carbsG: 3.1, fatG: 0.2),
  ),
  Ingredient(
    id: 'chinese_kale',
    name: 'คะน้า (สุก)',
    nameEn: 'chinese broccoli, cooked',
    per100g: Nutrients(kcal: 22, proteinG: 1.1, carbsG: 3.8, fatG: 0.7),
  ),
  Ingredient(
    id: 'carrot',
    name: 'แครอท',
    nameEn: 'carrot, raw',
    per100g: Nutrients(kcal: 41, proteinG: 0.9, carbsG: 9.6, fatG: 0.2),
  ),
  Ingredient(
    id: 'tomato',
    name: 'มะเขือเทศ',
    nameEn: 'tomato, raw',
    per100g: Nutrients(kcal: 18, proteinG: 0.9, carbsG: 3.9, fatG: 0.2),
  ),
  Ingredient(
    id: 'banana',
    name: 'กล้วยหอม',
    nameEn: 'banana, raw',
    per100g: Nutrients(kcal: 89, proteinG: 1.1, carbsG: 22.8, fatG: 0.3),
  ),
  Ingredient(
    id: 'apple',
    name: 'แอปเปิล',
    nameEn: 'apple, raw',
    per100g: Nutrients(kcal: 52, proteinG: 0.3, carbsG: 13.8, fatG: 0.2),
  ),
  Ingredient(
    id: 'guava',
    name: 'ฝรั่ง',
    nameEn: 'guava, raw',
    per100g: Nutrients(kcal: 68, proteinG: 2.6, carbsG: 14.3, fatG: 1.0),
  ),
  Ingredient(
    id: 'avocado',
    name: 'อะโวคาโด',
    nameEn: 'avocado, raw',
    per100g: Nutrients(kcal: 160, proteinG: 2.0, carbsG: 8.5, fatG: 14.7),
  ),
  Ingredient(
    id: 'peanut',
    name: 'ถั่วลิสง',
    nameEn: 'peanuts, raw',
    per100g: Nutrients(kcal: 567, proteinG: 25.8, carbsG: 16.1, fatG: 49.2),
  ),
  Ingredient(
    id: 'vegetable_oil',
    name: 'น้ำมันพืช',
    nameEn: 'vegetable oil',
    per100g: Nutrients(kcal: 884, proteinG: 0, carbsG: 0, fatG: 100),
  ),
  Ingredient(
    id: 'sugar',
    name: 'น้ำตาลทราย',
    nameEn: 'sugar, granulated',
    per100g: Nutrients(kcal: 387, proteinG: 0, carbsG: 100, fatG: 0),
  ),
];
