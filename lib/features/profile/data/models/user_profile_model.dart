import '../../domain/entities/user_profile.dart';

/// แปลง [UserProfile] กับ JSON ที่เก็บในเครื่อง
abstract final class UserProfileModel {
  static Map<String, dynamic> toJson(UserProfile profile) => {
    'weightKg': profile.weightKg,
    'heightCm': profile.heightCm,
    'age': profile.age,
    'sex': profile.sex.name,
    'activityLevel': profile.activityLevel?.name,
  };

  static UserProfile fromJson(Map<String, dynamic> json) {
    final activity = json['activityLevel'] as String?;
    return UserProfile(
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      age: json['age'] as int,
      sex: Sex.values.byName(json['sex'] as String),
      activityLevel: activity == null
          ? null
          : ActivityLevel.values.byName(activity),
    );
  }
}
