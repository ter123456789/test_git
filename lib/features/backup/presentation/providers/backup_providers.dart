import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../nutrition/data/datasources/nutrition_local_data_source.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../../profile/data/datasources/profile_local_data_source.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackupRepositoryImpl(
    NutritionLocalDataSource(prefs),
    ProfileLocalDataSource(prefs),
  );
});

/// นำเข้าไฟล์สำรอง แล้วให้ทุกหน้าโหลดข้อมูลใหม่จากเครื่อง
Future<void> restoreBackup(WidgetRef ref, String json) async {
  await ref.read(backupRepositoryProvider).restore(json);
  ref
    ..invalidate(profileProvider)
    ..invalidate(foodLogProvider)
    ..invalidate(ingredientsProvider);
}
