import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/app.dart';
import 'package:test_git/core/providers/shared_preferences_provider.dart';
import 'package:test_git/features/nutrition/presentation/pages/history_page.dart';
import 'package:test_git/features/nutrition/presentation/widgets/food_entry_tile.dart';
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
    expect(find.text('1979 kcal'), findsOneWidget);
    expect(find.text('เหลือ 1979 kcal'), findsOneWidget);
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

    expect(find.text('เหลือ 1719 kcal'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('260 kcal'), 200);
    expect(find.text('260 kcal'), findsOneWidget);

    // หน้าประวัติแสดงรายการของวันนี้
    await tester.scrollUntilVisible(find.byTooltip('ประวัติการกิน'), -200);
    await tester.tap(find.byTooltip('ประวัติการกิน'));
    await tester.pumpAndSettle();
    expect(find.text('ประวัติการกิน'), findsWidgets);
    final historyList = find
        .descendant(
          of: find.byType(HistoryPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('รายการวันนี้'),
      200,
      scrollable: historyList,
    );
    expect(find.text('รายการวันนี้'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(FoodEntryTile),
      200,
      scrollable: historyList,
    );
    expect(find.widgetWithText(FoodEntryTile, '260 kcal'), findsOneWidget);
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

    // 100 กรัม = 133 kcal และตั้งชื่อไทยจากคำค้นให้ก่อน
    await tester.tap(
      find.widgetWithText(ListTile, 'Chicken, breast, meat and skin, raw'),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'อกไก่ย่าง'), findsOneWidget);
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('133 kcal'), 200);
    expect(find.text('133 kcal'), findsOneWidget);
    expect(find.text('อกไก่ย่าง'), findsOneWidget);

    // เปิดหน้าเลือกใหม่ ค้นด้วยภาษาอังกฤษ ต้องเจอในเครื่องโดยไม่ยิง API
    await tester.scrollUntilVisible(find.text('เพิ่มวัตถุดิบ'), -200);
    await tester.tap(find.text('เพิ่มวัตถุดิบ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'meat and skin');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'อกไก่ย่าง'), findsOneWidget);

    // ค้นภาษาไทยแบบไม่ใส่วรรณยุกต์ก็เจอ
    await tester.enterText(find.byType(TextField).first, 'อกไกยาง');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'อกไก่ย่าง'), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('เพิ่มวัตถุดิบใหม่: ใส่ชื่อกับน้ำหนัก แอปเติมค่าโภชนาการให้', (
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
    await tester.tap(find.text('วัตถุดิบใหม่'));
    await tester.pumpAndSettle();

    // ชื่อที่มีในเครื่อง: เติมค่าจากในเครื่อง ไม่ยิง API (ข้าวสวย 130 kcal/100 ก.)
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ข้าวสวยหุงใหม่');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('ใช้ค่าจาก: ข้าวสวย'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '130'), findsOneWidget);

    await tester.enterText(fields.at(1), '200');
    await tester.pumpAndSettle();
    expect(find.text('200 กรัม = 260 kcal'), findsOneWidget);

    // แก้ตัวเลขเอง สถานะต้องเปลี่ยน
    await tester.enterText(find.widgetWithText(TextFormField, '130'), '150');
    await tester.pumpAndSettle();
    expect(find.text('แก้ค่าเองแล้ว'), findsOneWidget);
    expect(find.text('200 กรัม = 300 kcal'), findsOneWidget);

    // บันทึกแล้วกลับหน้าหลักทันที พร้อมรายการใหม่
    await tester.ensureVisible(find.text('บันทึกและเพิ่มในรายการที่กิน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกและเพิ่มในรายการที่กิน'));
    await tester.pumpAndSettle();
    expect(find.text('โภชนาการวันนี้'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ข้าวสวยหุงใหม่'), 200);
    expect(find.text('300 kcal'), findsOneWidget);

    // ชื่อที่ไม่มีในเครื่อง: ค้นจาก USDA แทน
    await tester.scrollUntilVisible(find.text('เพิ่มวัตถุดิบ'), -200);
    await tester.tap(find.text('เพิ่มวัตถุดิบ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('วัตถุดิบใหม่'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'ปีกไก่ทอด');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('(USDA)'), findsOneWidget);
    expect(find.text('เลือกอื่น (1)'), findsOneWidget);
  });
}
