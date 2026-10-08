import 'package:equatable/equatable.dart';

class Nutrients extends Equatable {
  const Nutrients({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  static const zero = Nutrients(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0);

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Nutrients operator +(Nutrients other) => Nutrients(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
  );

  Nutrients scale(double factor) => Nutrients(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
  );

  static Nutrients sum(Iterable<Nutrients> items) =>
      items.fold(zero, (total, n) => total + n);

  @override
  List<Object?> get props => [kcal, proteinG, carbsG, fatG];
}
