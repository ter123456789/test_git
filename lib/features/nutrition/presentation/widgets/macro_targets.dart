import '../../domain/entities/nutrients.dart';

/// เป้าหมายสารอาหารหลักโดยประมาณ แบ่งพลังงานเป็น
/// คาร์บ 50% · โปรตีน 20% · ไขมัน 30% (1 ก. = 4/4/9 kcal)
Nutrients macroTargetsFor(double kcal) => Nutrients(
  kcal: kcal,
  proteinG: kcal * 0.20 / 4,
  carbsG: kcal * 0.50 / 4,
  fatG: kcal * 0.30 / 9,
);
