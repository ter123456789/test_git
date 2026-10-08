import 'package:equatable/equatable.dart';

import '../entities/user_profile.dart';

class EnergyNeeds extends Equatable {
  const EnergyNeeds({
    required this.bmr,
    required this.tdee,
    required this.bmi,
    required this.isActivityAssumed,
  });

  /// พลังงานที่ร่างกายใช้ขณะพัก (kcal/วัน)
  final double bmr;

  /// พลังงานที่ใช้ทั้งวันเมื่อรวมกิจกรรม (kcal/วัน)
  final double tdee;

  final double bmi;

  /// true เมื่อ user ไม่ได้ระบุกิจกรรม และใช้ค่า sedentary แทน
  final bool isActivityAssumed;

  @override
  List<Object?> get props => [bmr, tdee, bmi, isActivityAssumed];
}

/// คำนวณ BMR ด้วยสูตร Mifflin-St Jeor และ TDEE = BMR × activity factor
class CalculateEnergyNeeds {
  const CalculateEnergyNeeds();

  EnergyNeeds call(UserProfile profile) {
    final base =
        10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
    final bmr = switch (profile.sex) {
      Sex.male => base + 5,
      Sex.female => base - 161,
    };
    final activity = profile.activityLevel ?? ActivityLevel.sedentary;
    final heightM = profile.heightCm / 100;

    return EnergyNeeds(
      bmr: bmr,
      tdee: bmr * activity.factor,
      bmi: profile.weightKg / (heightM * heightM),
      isActivityAssumed: profile.activityLevel == null,
    );
  }
}
