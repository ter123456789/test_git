import 'package:equatable/equatable.dart';

enum Sex { male, female }

/// ระดับกิจกรรม พร้อมตัวคูณ (activity factor) สำหรับคำนวณ TDEE
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.factor);

  final double factor;
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    this.activityLevel,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final Sex sex;

  /// ไม่บังคับกรอก ถ้าเป็น null จะคำนวณโดยถือว่าไม่ค่อยออกกำลังกาย
  final ActivityLevel? activityLevel;

  @override
  List<Object?> get props => [weightKg, heightCm, age, sex, activityLevel];
}
