import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  /// คืน null ถ้ายังไม่เคยกรอกโปรไฟล์
  Future<UserProfile?> getProfile();

  Future<void> saveProfile(UserProfile profile);
}
