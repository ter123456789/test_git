import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/features/nutrition/data/datasources/nutrition_local_data_source.dart';
import 'package:test_git/features/nutrition/data/datasources/open_food_facts_remote_data_source.dart';
import 'package:test_git/features/nutrition/data/datasources/thai_food_terms.dart';
import 'package:test_git/features/nutrition/data/datasources/usda_remote_data_source.dart';
import 'package:test_git/features/nutrition/data/models/usda_food_mapper.dart';
import 'package:test_git/features/nutrition/data/repositories/ingredient_repository_impl.dart';
import 'package:test_git/features/nutrition/domain/entities/ingredient.dart';
import 'package:test_git/features/nutrition/domain/entities/remote_search_result.dart';

/// รูปแบบเดียวกับ response จริงของ POST /fdc/v1/foods/search
Map<String, dynamic> food(int fdcId, String description, Map<int, num> n) => {
  'fdcId': fdcId,
  'description': description,
  'dataType': 'Foundation',
  'foodNutrients': [
    for (final e in n.entries) {'nutrientId': e.key, 'value': e.value},
  ],
};

final sampleResponse = {
  'totalHits': 3,
  'foods': [
    // Foundation: ไม่มี 1008 มีแต่ Atwater และคาร์บติดลบ
    food(2727569, 'Chicken, breast, meat and skin, raw', {
      1003: 21.4,
      1004: 4.78,
      1005: -0.428,
      2047: 127,
      2048: 133,
    }),
    // SR Legacy: มี 1008
    food(174608, 'Chicken breast, roll, oven-roasted', {
      1003: 14.6,
      1004: 7.65,
      1005: 1.79,
      1008: 134,
    }),
    // ไม่มีข้อมูลโภชนาการ ต้องถูกตัดทิ้ง
    food(2759004, 'Lunchmeat, chicken breast, sliced', {}),
  ],
};

void main() {
  group('UsdaFoodMapper', () {
    test('ใช้ Atwater specific เมื่อไม่มี 1008 และปัดค่าติดลบเป็น 0', () {
      final i = UsdaFoodMapper.toIngredient(
        (sampleResponse['foods'] as List).first as Map<String, dynamic>,
      )!;
      expect(i.id, 'usda_2727569');
      expect(i.source, IngredientSource.usda);
      expect(i.per100g.kcal, 133);
      expect(i.per100g.carbsG, 0);
      expect(i.per100g.proteinG, 21.4);
    });

    test('ไม่มีค่าพลังงาน: ประมาณจาก 4/4/9', () {
      final i = UsdaFoodMapper.toIngredient(
        food(1, 'x', {1003: 10, 1005: 20, 1004: 5}),
      )!;
      expect(i.per100g.kcal, 4 * 10 + 4 * 20 + 9 * 5);
    });

    test('ไม่มีข้อมูลเลย: คืน null', () {
      expect(UsdaFoodMapper.toIngredient(food(1, 'x', {})), isNull);
    });
  });

  group('ThaiQueryTranslator', () {
    test('ภาษาอังกฤษคืนคำเดิม', () {
      expect(ThaiQueryTranslator.toEnglish(' salmon '), 'salmon');
    });

    test('คำไทยที่ตรงในตาราง', () {
      expect(ThaiQueryTranslator.toEnglish('อกไก่'), 'chicken breast raw');
    });

    test('ขึ้นต้นด้วยคำในตาราง ใช้คำที่ยาวที่สุด', () {
      expect(ThaiQueryTranslator.toEnglish('อกไก่ย่าง'), 'chicken breast raw');
      expect(ThaiQueryTranslator.toEnglish('ไก่ทอด'), 'chicken raw');
    });

    test('คำในตารางที่อยู่กลางคำไม่นับ', () {
      // "ขนมจีบ" มี "นม" อยู่ข้างใน แต่ไม่ใช่ milk
      expect(ThaiQueryTranslator.toEnglish('ขนมจีบ'), isNull);
    });
  });

  group('IngredientRepositoryImpl.searchRemote', () {
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

    test('แปลคำไทย ส่ง request ถูกต้อง และตัดรายการที่ไม่มีข้อมูล', () async {
      late http.Request sent;
      final repo = repoWith((req) async {
        sent = req;
        return http.Response(jsonEncode(sampleResponse), 200);
      });

      final result = await repo.searchRemote('อกไก่');

      expect(sent.method, 'POST');
      expect(sent.url.host, 'api.nal.usda.gov');
      expect(sent.url.queryParameters['api_key'], 'KEY');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['query'], 'chicken breast raw');
      expect(body['dataType'], ['Foundation', 'SR Legacy']);

      expect(result.query, 'chicken breast raw');
      expect(result.items.map((i) => i.id), ['usda_2727569', 'usda_174608']);
    });

    test('คำไทยที่ไม่รู้จัก ไม่ยิง API', () async {
      var called = false;
      final repo = repoWith((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        repo.searchRemote('ขนมจีบ'),
        throwsA(isA<UntranslatableQueryException>()),
      );
      expect(called, isFalse);
    });

    test('HTTP 429 → RateLimitedException', () async {
      final repo = repoWith((_) async => http.Response('', 429));
      await expectLater(
        repo.searchRemote('rice'),
        throwsA(isA<RateLimitedException>()),
      );
    });

    test('เชื่อมต่อไม่ได้ → RemoteUnavailableException', () async {
      final repo = repoWith((_) async => throw http.ClientException('offline'));
      await expectLater(
        repo.searchRemote('rice'),
        throwsA(isA<RemoteUnavailableException>()),
      );
    });
  });
}
