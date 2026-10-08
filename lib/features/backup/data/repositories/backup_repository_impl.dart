import 'dart:convert';

import '../../../nutrition/data/datasources/nutrition_local_data_source.dart';
import '../../../nutrition/data/models/nutrition_models.dart';
import '../../../profile/data/datasources/profile_local_data_source.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../domain/entities/backup_summary.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._nutrition, this._profile);

  /// ใช้แยกไฟล์ของแอปนี้ออกจาก JSON อื่น
  static const _format = 'prachaya-healthy-body-backup';
  static const _version = 1;

  final NutritionLocalDataSource _nutrition;
  final ProfileLocalDataSource _profile;

  @override
  String exportJson({DateTime? now}) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': _format,
        'version': _version,
        'exportedAt': (now ?? DateTime.now()).toIso8601String(),
        'profile': _profile.read(),
        'foodLog': _nutrition.readFoodLog(),
        'savedIngredients': _nutrition.readSavedIngredients(),
      });

  @override
  BackupSummary inspect(String json) {
    final data = _parse(json);
    return BackupSummary(
      exportedAt: data.exportedAt,
      hasProfile: data.profile != null,
      entryCount: data.foodLog.length,
      dayCount: data.foodLog
          .map((e) {
            final d = DateTime.parse(e['eatenAt'] as String);
            return DateTime(d.year, d.month, d.day);
          })
          .toSet()
          .length,
      ingredientCount: data.savedIngredients.length,
    );
  }

  @override
  Future<void> restore(String json) async {
    final data = _parse(json);
    if (data.profile == null) {
      await _profile.clear();
    } else {
      await _profile.write(data.profile!);
    }
    await _nutrition.writeFoodLog(data.foodLog);
    await _nutrition.writeSavedIngredients(data.savedIngredients);
  }

  /// แปลงและตรวจทุกรายการด้วย model จริง เพื่อไม่ให้ข้อมูลเสียหลุดเข้าเครื่อง
  static _BackupData _parse(String json) {
    try {
      final root = jsonDecode(json);
      if (root is! Map<String, dynamic> || root['format'] != _format) {
        throw const InvalidBackupException('ไม่ใช่ไฟล์สำรองของแอปนี้');
      }
      final version = root['version'];
      if (version is! int || version > _version) {
        throw InvalidBackupException('ไม่รองรับไฟล์รุ่น $version');
      }

      final profile = root['profile'] as Map<String, dynamic>?;
      final foodLog = (root['foodLog'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final saved = (root['savedIngredients'] as List? ?? const [])
          .cast<Map<String, dynamic>>();

      if (profile != null) UserProfileModel.fromJson(profile);
      foodLog.forEach(NutritionModels.entryFromJson);
      saved.forEach(NutritionModels.ingredientFromJson);

      return _BackupData(
        exportedAt: DateTime.tryParse(root['exportedAt'] as String? ?? ''),
        profile: profile,
        foodLog: foodLog,
        savedIngredients: saved,
      );
    } on InvalidBackupException {
      rethrow;
    } catch (e) {
      // FormatException, TypeError, ArgumentError จากข้อมูลที่ไม่ถูกต้อง
      throw InvalidBackupException('ข้อมูลในไฟล์เสียหาย ($e)');
    }
  }
}

class _BackupData {
  const _BackupData({
    required this.exportedAt,
    required this.profile,
    required this.foodLog,
    required this.savedIngredients,
  });

  final DateTime? exportedAt;
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> foodLog;
  final List<Map<String, dynamic>> savedIngredients;
}
