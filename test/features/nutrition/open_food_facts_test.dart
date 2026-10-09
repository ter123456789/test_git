import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/features/nutrition/data/datasources/nutrition_local_data_source.dart';
import 'package:test_git/features/nutrition/data/datasources/open_food_facts_remote_data_source.dart';
import 'package:test_git/features/nutrition/data/datasources/usda_remote_data_source.dart';
import 'package:test_git/features/nutrition/data/models/nutrition_models.dart';
import 'package:test_git/features/nutrition/data/models/open_food_facts_mapper.dart';
import 'package:test_git/features/nutrition/data/repositories/ingredient_repository_impl.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/nutrients.dart';
import 'package:test_git/features/nutrition/domain/entities/remote_search_result.dart';

const barcode = '8850999320007';

/// รูปแบบเดียวกับ response จริงของ GET /api/v2/product/{barcode}
final sampleProduct = {
  'code': barcode,
  'product_name': 'Lactasoy Soy Milk',
  'product_name_en': 'Soy Milk',
  'nutriments': {
    'energy-kcal_100g': 58,
    'proteins_100g': 2.5,
    // บางสินค้าส่งค่ามาเป็นข้อความ
    'carbohydrates_100g': '8.3',
    'fat_100g': 1.7,
  },
};

void main() {
  group('OpenFoodFactsMapper', () {
    test('แปลงค่าต่อ 100 กรัม', () {
      final i = OpenFoodFactsMapper.toIngredient(barcode, sampleProduct)!;
      expect(i.id, 'off_$barcode');
      expect(i.barcode, barcode);
      expect(i.source, IngredientSource.openFoodFacts);
      expect(i.name, 'Lactasoy Soy Milk');
      expect(i.nameEn, 'Soy Milk');
      expect(
        i.per100g,
        const Nutrients(kcal: 58, proteinG: 2.5, carbsG: 8.3, fatG: 1.7),
      );
    });

    test('มีชื่อไทย: ใช้ชื่อไทยก่อน', () {
      final i = OpenFoodFactsMapper.toIngredient(barcode, {
        ...sampleProduct,
        'product_name_th': 'นมถั่วเหลือง',
      })!;
      expect(i.name, 'นมถั่วเหลือง');
    });

    test('มีแค่กิโลจูล: แปลงเป็น kcal', () {
      final i = OpenFoodFactsMapper.toIngredient(barcode, {
        'product_name': 'x',
        'nutriments': {'energy_100g': 418.4},
      })!;
      expect(i.per100g.kcal, closeTo(100, 0.001));
    });

    test('ไม่มีข้อมูลโภชนาการ: คืน null', () {
      expect(
        OpenFoodFactsMapper.toIngredient(barcode, {'product_name': 'x'}),
        isNull,
      );
    });
  });

  group('IngredientRepositoryImpl.lookupBarcode', () {
    late NutritionLocalDataSource local;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = NutritionLocalDataSource(await SharedPreferences.getInstance());
    });

    IngredientRepositoryImpl repoWith(MockClientHandler handler) =>
        IngredientRepositoryImpl(
          local,
          UsdaRemoteDataSource(client: MockClient(handler), apiKey: 'KEY'),
          OpenFoodFactsRemoteDataSource(client: MockClient(handler)),
        );

    test('ส่ง request ถูกต้อง และแปลงผล', () async {
      late http.Request sent;
      final repo = repoWith((req) async {
        sent = req;
        return http.Response(
          jsonEncode({'status': 1, 'product': sampleProduct}),
          200,
        );
      });

      final found = await repo.lookupBarcode(barcode);

      expect(sent.method, 'GET');
      expect(sent.url.host, 'world.openfoodfacts.org');
      expect(sent.url.path, '/api/v2/product/$barcode');
      expect(sent.headers['User-Agent'], isNotEmpty);
      expect(found?.id, 'off_$barcode');
    });

    test('บาร์โค้ดที่เก็บในเครื่องแล้ว ไม่ยิง API', () async {
      const saved = Ingredient(
        id: 'custom_1',
        name: 'ขนมปังร้านแถวบ้าน',
        per100g: Nutrients(kcal: 260, proteinG: 8, carbsG: 50, fatG: 3),
        source: IngredientSource.custom,
        barcode: barcode,
      );
      await local.writeSavedIngredients([
        NutritionModels.ingredientToJson(saved),
      ]);
      var called = false;
      final repo = repoWith((_) async {
        called = true;
        return http.Response('', 500);
      });

      expect(await repo.lookupBarcode(barcode), saved);
      expect(called, isFalse);
    });

    test('ไม่พบสินค้า (404 หรือ status 0): คืน null', () async {
      expect(
        await repoWith(
          (_) async => http.Response('{"status":0}', 404),
        ).lookupBarcode(barcode),
        isNull,
      );
      expect(
        await repoWith(
          (_) async => http.Response('{"status":0}', 200),
        ).lookupBarcode(barcode),
        isNull,
      );
    });

    test('429 และ 5xx แปลงเป็น exception ของโดเมน', () async {
      await expectLater(
        repoWith((_) async => http.Response('', 429)).lookupBarcode(barcode),
        throwsA(isA<RateLimitedException>()),
      );
      await expectLater(
        repoWith((_) async => http.Response('', 503)).lookupBarcode(barcode),
        throwsA(isA<RemoteUnavailableException>()),
      );
    });
  });
}
