import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/profile_local_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/calculate_energy_needs.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ProfileLocalDataSource(ref.watch(sharedPreferencesProvider)),
  ),
);

final calculateEnergyNeedsProvider = Provider(
  (ref) => const CalculateEnergyNeeds(),
);

/// โปรไฟล์ของ user ค่าเป็น null ถ้ายังไม่เคยกรอก
final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() =>
      ref.watch(profileRepositoryProvider).getProfile();

  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncData(profile);
  }
}

final energyNeedsProvider = Provider<EnergyNeeds?>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return null;
  return ref.watch(calculateEnergyNeedsProvider)(profile);
});
