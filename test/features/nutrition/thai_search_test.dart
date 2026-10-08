import 'package:flutter_test/flutter_test.dart';
import 'package:test_git/core/utils/thai_text.dart';
import 'package:test_git/features/nutrition/data/datasources/builtin_ingredients.dart';
import 'package:test_git/features/nutrition/data/datasources/ingredient_matcher.dart';
import 'package:test_git/features/nutrition/data/datasources/thai_food_terms.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/nutrients.dart';

void main() {
  group('ThaiText.normalize', () {
    test('ไม่สนวรรณยุกต์ การันต์ ไม้ไต่คู้ และช่องว่าง', () {
      expect(
        ThaiText.normalize('สตรอว์เบอร์รี่'),
        ThaiText.normalize('สตรอวเบอรรี'),
      );
      expect(ThaiText.normalize('บร็อคโคลี่'), ThaiText.normalize('บรอคโคลี'));
      expect(ThaiText.normalize('อก ไก่'), ThaiText.normalize('อกไก'));
    });

    test('สระอำที่พิมพ์เป็น นิคหิต + สระอา', () {
      expect(ThaiText.normalize('นําผึ้ง'), ThaiText.normalize('น้ำผึ้ง'));
    });
  });

  group('ThaiQueryTranslator แบบหลวม', () {
    test('ไม่ใส่วรรณยุกต์', () {
      expect(ThaiQueryTranslator.toEnglish('ไก'), 'chicken raw');
      expect(ThaiQueryTranslator.toEnglish('กลวยหอม'), 'banana raw');
    });

    test('สะกดผิดเล็กน้อย', () {
      expect(ThaiQueryTranslator.toEnglish('บรอคโคลี'), 'broccoli raw');
      expect(ThaiQueryTranslator.toEnglish('สตรอเบอรี'), 'strawberries raw');
    });

    test('คำที่เพิ่มใหม่', () {
      expect(ThaiQueryTranslator.toEnglish('ไข่ต้ม'), 'egg whole hard-boiled');
      expect(ThaiQueryTranslator.toEnglish('เห็ดเข็มทอง'), 'enoki mushrooms');
      expect(ThaiQueryTranslator.toEnglish('กาแฟเย็น'), 'coffee brewed');
    });

    test('คำสั้นที่ไม่ตรงไม่เดา', () {
      expect(ThaiQueryTranslator.toEnglish('ขนมจีบ'), isNull);
      expect(ThaiQueryTranslator.toEnglish('กข'), isNull);
    });
  });

  group('IngredientMatcher', () {
    const usdaChicken = Ingredient(
      id: 'usda_1',
      name: 'Chicken, breast, meat and skin, raw',
      nameEn: 'Chicken, breast, meat and skin, raw',
      per100g: Nutrients.zero,
      source: IngredientSource.usda,
    );
    const eggplant = Ingredient(
      id: 'usda_2',
      name: 'Eggplant, raw',
      nameEn: 'Eggplant, raw',
      per100g: Nutrients.zero,
      source: IngredientSource.usda,
    );
    final items = [...builtinIngredients, usdaChicken, eggplant];
    List<String> ids(String q) =>
        IngredientMatcher.search(items, q).map((i) => i.id).toList();

    test('คำค้นว่างคืนทุกรายการ', () {
      expect(IngredientMatcher.search(items, '  '), items);
    });

    test('ค้นด้วยชื่ออังกฤษของวัตถุดิบในแอป', () {
      expect(ids('salmon'), ['salmon']);
    });

    test('ไม่สนวรรณยุกต์', () {
      expect(ids('กลวยหอม'), ['banana']);
    });

    test('พิมพ์ผิดเล็กน้อย', () {
      expect(ids('บรอคโคลี'), contains('broccoli'));
    });

    test('ภาษาไทยเจอวัตถุดิบ USDA ที่เป็นชื่ออังกฤษ โดยชื่อไทยตรงขึ้นก่อน', () {
      // สะโพกไก่ติดมาด้วยจากการค้นแบบพิมพ์ผิดได้ ("อกไก" กับ "พกไก" ต่างกัน 1 ตัว)
      // แต่ชื่อที่ตรงต้องขึ้นก่อนเสมอ
      final result = ids('อกไก่');
      expect(result.first, 'chicken_breast');
      expect(result, contains('usda_1'));
    });

    test('"ไข่" ไม่เจอ eggplant และไข่ขึ้นก่อน "ไขมัน"', () {
      final result = ids('ไข่');
      expect(result.first, 'egg');
      expect(result, isNot(contains('usda_2')));
    });
  });
}
