import 'package:flutter_test/flutter_test.dart';
import 'package:test_git/features/profile/domain/entities/user_profile.dart';
import 'package:test_git/features/profile/domain/usecases/calculate_energy_needs.dart';

void main() {
  const calculate = CalculateEnergyNeeds();

  test('ผู้ชาย ใช้สูตร Mifflin-St Jeor และตัวคูณกิจกรรม', () {
    final needs = calculate(
      const UserProfile(
        weightKg: 70,
        heightCm: 175,
        age: 30,
        sex: Sex.male,
        activityLevel: ActivityLevel.moderate,
      ),
    );

    // 10*70 + 6.25*175 - 5*30 + 5 = 1648.75
    expect(needs.bmr, closeTo(1648.75, 0.001));
    expect(needs.tdee, closeTo(1648.75 * 1.55, 0.001));
    expect(needs.bmi, closeTo(22.857, 0.001));
    expect(needs.isActivityAssumed, isFalse);
  });

  test('ผู้หญิง ไม่ระบุกิจกรรม ใช้ sedentary', () {
    final needs = calculate(
      const UserProfile(weightKg: 55, heightCm: 160, age: 25, sex: Sex.female),
    );

    // 10*55 + 6.25*160 - 5*25 - 161 = 1264
    expect(needs.bmr, closeTo(1264, 0.001));
    expect(needs.tdee, closeTo(1264 * 1.2, 0.001));
    expect(needs.isActivityAssumed, isTrue);
  });
}
