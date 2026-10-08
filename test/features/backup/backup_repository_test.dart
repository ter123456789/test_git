import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_git/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:test_git/features/backup/domain/entities/backup_summary.dart';
import 'package:test_git/features/nutrition/data/datasources/nutrition_local_data_source.dart';
import 'package:test_git/features/profile/data/datasources/profile_local_data_source.dart';

void main() {
  const profile =
      '{"weightKg":70,"heightCm":175,"age":30,"sex":"male","activityLevel":null}';
  final rice = {
    'id': 'rice',
    'name': 'ข้าวสวย',
    'nameEn': null,
    'per100g': {'kcal': 130, 'proteinG': 2.7, 'carbsG': 28, 'fatG': 0.3},
    'source': 'custom',
  };
  Map<String, dynamic> entry(String id, String eatenAt) => {
    'id': id,
    'ingredient': rice,
    'grams': 100,
    'eatenAt': eatenAt,
  };

  Future<(BackupRepositoryImpl, SharedPreferences)> repoWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return (
      BackupRepositoryImpl(
        NutritionLocalDataSource(prefs),
        ProfileLocalDataSource(prefs),
      ),
      prefs,
    );
  }

  test('ส่งออกแล้วนำเข้าในเครื่องใหม่ ได้ข้อมูลเดิมครบ', () async {
    final (source, _) = await repoWith({
      'user_profile': profile,
      'food_log': jsonEncode([
        entry('a', '2026-10-07T08:00:00.000'),
        entry('b', '2026-10-07T19:00:00.000'),
        entry('c', '2026-10-08T12:00:00.000'),
      ]),
      'custom_ingredients': jsonEncode([rice]),
    });
    final json = source.exportJson(now: DateTime(2026, 10, 8, 9, 30));

    final (target, prefs) = await repoWith({});
    expect(
      target.inspect(json),
      BackupSummary(
        exportedAt: DateTime(2026, 10, 8, 9, 30),
        hasProfile: true,
        entryCount: 3,
        dayCount: 2,
        ingredientCount: 1,
      ),
    );

    await target.restore(json);
    expect(jsonDecode(prefs.getString('user_profile')!), jsonDecode(profile));
    expect(jsonDecode(prefs.getString('food_log')!), hasLength(3));
    expect(jsonDecode(prefs.getString('custom_ingredients')!), [rice]);
  });

  test('นำเข้าแทนที่ข้อมูลเดิมทั้งหมด', () async {
    final (repo, prefs) = await repoWith({
      'user_profile': profile,
      'food_log': jsonEncode([entry('old', '2026-10-01T08:00:00.000')]),
    });
    final backup = jsonEncode({
      'format': 'prachaya-healthy-body-backup',
      'version': 1,
      'profile': null,
      'foodLog': [entry('new', '2026-10-08T08:00:00.000')],
      'savedIngredients': [],
    });

    await repo.restore(backup);

    expect(prefs.getString('user_profile'), isNull);
    final log = jsonDecode(prefs.getString('food_log')!) as List;
    expect(log.map((e) => e['id']), ['new']);
  });

  group('ไฟล์ที่ใช้ไม่ได้ ไม่แตะข้อมูลเดิม', () {
    final invalid = {
      'ไม่ใช่ JSON': 'hello',
      'JSON ของแอปอื่น': '{"foo": 1}',
      'ไฟล์รุ่นใหม่กว่า': jsonEncode({
        'format': 'prachaya-healthy-body-backup',
        'version': 99,
      }),
      'รายการเสีย': jsonEncode({
        'format': 'prachaya-healthy-body-backup',
        'version': 1,
        'foodLog': [
          {'id': 'x', 'grams': 'เยอะ'},
        ],
      }),
    };

    for (final MapEntry(key: name, value: json) in invalid.entries) {
      test(name, () async {
        final (repo, prefs) = await repoWith({'user_profile': profile});

        expect(
          () => repo.inspect(json),
          throwsA(isA<InvalidBackupException>()),
        );
        await expectLater(
          repo.restore(json),
          throwsA(isA<InvalidBackupException>()),
        );
        expect(prefs.getString('user_profile'), profile);
      });
    }
  });
}
