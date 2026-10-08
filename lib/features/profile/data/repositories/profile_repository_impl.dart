import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._local);

  final ProfileLocalDataSource _local;

  @override
  Future<UserProfile?> getProfile() async {
    final json = _local.read();
    return json == null ? null : UserProfileModel.fromJson(json);
  }

  @override
  Future<void> saveProfile(UserProfile profile) =>
      _local.write(UserProfileModel.toJson(profile));
}
