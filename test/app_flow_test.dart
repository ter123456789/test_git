import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/app.dart';
import 'package:test_git/core/providers/shared_preferences_provider.dart';
import 'package:test_git/features/nutrition/presentation/providers/nutrition_providers.dart';

import 'features/nutrition/usda_test.dart' show sampleResponse;

void main() {
  testWidgets('กรอกโปรไฟล์ครั้งแรก แล้วเพิ่มวัตถุดิบเข้าบันทึกวันนี้', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NutritionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // หน้ากรอกข้อมูลครั้งแรก (ไม่กรอกกิจกรรม)
    expect(find.text('ข้อมูลของคุณ'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '70');
    await tester.enterText(fields.at(1), '175');
    await tester.enterText(fields.at(2), '30');
    await tester.tap(find.text('ชาย'));
    await tester.tap(find.text('เริ่มใช้งาน'));
    await tester.pumpAndSettle();

    // หน้าหลัก: 1648.75 * 1.2 = 1978.5 → 1979
    expect(find.text('โภชนาการวันนี้'), findsOneWidget);
    expect(find.text('0 / 1979 kcal'), findsOneWidget);
    expect(find.textContaining('ยังไม่ได้ระบุกิจกรรม'), findsOneWidget);

    // เพิ่มข้าวสวย 200 กรัม = 260 kcal
    await tester.tap(find.text('เพิ่มวัตถุดิบ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ข้าวสวย');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'ข้าวสวย'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '200');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(find.text('260 / 1979 kcal'), findsOneWidget);
    expect(find.text('260 kcal'), findsOneWidget);
  });

  testWidgets('ค้นหาด้วยภาษาไทยจาก USDA แล้วเลือกเก็บไว้ใช้ออฟไลน์', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_profile':
          '{"weightKg":70,"heightCm":175,"age":30,"sex":"male",'
          '"activityLevel":null}',
    });
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(jsonEncode(sampleResponse), 200);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          httpClientProvider.overrideWithValue(client),
        ],
        child: const NutritionApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มวัตถุดิบ'));
    await tester.pumpAndSettle();

    // พิมพ์อย่างเดียวยังไม่ยิง API
    await tester.enterText(find.byType(TextField).first, 'อกไก่ย่าง');
    await tester.pumpAndSettle();
    expect(requests, 0);

    await tester.tap(find.text('ค้นหา "อกไก่ย่าง" จาก USDA'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('ค้นด้วยคำว่า "chicken breast raw"'), findsOne);

    // 100 กรัม = 133 kcal
    await tester.tap(
      find.widgetWithText(ListTile, 'Chicken, breast, meat and skin, raw'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();
    expect(find.text('133 / 1979 kcal'), findsOneWidget);

    // เปิดหน้าเลือกใหม่ ค้นด้วยภาษาอังกฤษ ต้องเจอในเครื่องโดยไม่ยิง API
    await tester.tap(find.text('เพิ่มวัตถุดิบ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'meat and skin');
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(ListTile, 'Chicken, breast, meat and skin, raw'),
      findsOneWidget,
    );
    expect(requests, 1);
  });
}
