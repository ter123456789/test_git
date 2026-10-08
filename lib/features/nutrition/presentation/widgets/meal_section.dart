import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pill_progress_bar.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/usecases/meal_balance.dart';
import 'food_entry_tile.dart';

extension MealStyle on Meal {
  IconData get icon => switch (this) {
    Meal.breakfast => Icons.wb_twilight_rounded,
    Meal.lunch => Icons.wb_sunny_rounded,
    Meal.snack => Icons.cookie_rounded,
    Meal.dinner => Icons.nights_stay_rounded,
  };
}

extension NutrientStyle on Nutrient {
  Color get color => switch (this) {
    Nutrient.kcal => AppColors.limeStrong,
    Nutrient.protein => AppColors.protein,
    Nutrient.carbs => AppColors.carbs,
    Nutrient.fat => AppColors.fat,
  };
}

/// รายการของวัน แยกเป็นการ์ดตามมื้อ แต่ละมื้อบอกว่าขาดหรือเกินอะไร
class MealSectionList extends StatelessWidget {
  const MealSectionList({
    super.key,
    required this.entries,
    required this.dayTarget,
    required this.emptyText,
    required this.onDelete,
    required this.onOpen,
  });

  /// รายการของวันเดียว
  final List<FoodEntry> entries;

  /// null ถ้ายังไม่มีข้อมูลส่วนตัว จะแสดงแค่รายการโดยไม่เทียบเป้า
  final Nutrients? dayTarget;
  final String emptyText;
  final ValueChanged<FoodEntry> onDelete;
  final ValueChanged<Meal> onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return FoodEntryList(
        entries: const [],
        emptyText: emptyText,
        onDelete: onDelete,
      );
    }
    final targets = dayTarget == null
        ? null
        : MealPlanner.targets(dayTarget!, entries);
    final eaten = MealPlanner.eatenByMeal(entries);
    return Column(
      children: [
        for (final meal in Meal.values)
          if (entries.where((e) => e.meal == meal).toList()
              case final mealEntries when mealEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MealCard(
                meal: meal,
                entries: mealEntries,
                balance: targets == null
                    ? null
                    : MealBalance(
                        meal: meal,
                        eaten: eaten[meal]!,
                        target: targets[meal]!,
                      ),
                onDelete: onDelete,
                onOpen: () => onOpen(meal),
              ),
            ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.entries,
    required this.balance,
    required this.onDelete,
    required this.onOpen,
  });

  final Meal meal;
  final List<FoodEntry> entries;
  final MealBalance? balance;
  final ValueChanged<FoodEntry> onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcal = Nutrients.sum(entries.map((e) => e.nutrients)).kcal;
    final balance = this.balance;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.soft,
                        child: Icon(meal.icon, size: 20, color: AppColors.ink),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meal.label,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: '${kcal.round()}',
                          style: theme.textTheme.titleMedium,
                          children: [
                            TextSpan(
                              text: balance == null
                                  ? ' kcal'
                                  : ' / ${balance.target.kcal.round()} kcal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  if (balance != null) ...[
                    const SizedBox(height: 10),
                    MacroBars(balance: balance),
                    const SizedBox(height: 10),
                    BalanceChips(balance: balance),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 4, 8),
            child: Column(
              children: [
                for (final e in entries)
                  FoodEntryTile(entry: e, onDelete: () => onDelete(e)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// แถบโปรตีน คาร์บ ไขมัน ของมื้อเทียบกับเป้า วางเรียงกันในแถวเดียว
class MacroBars extends StatelessWidget {
  const MacroBars({super.key, required this.balance});

  final MealBalance balance;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Row(
      children: [
        for (final (i, n) in Nutrient.macros.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${n.label} ${balance.of(n).eaten.round()}'
                  '/${balance.of(n).target.round()}',
                  style: small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                PillProgressBar(
                  value: balance.of(n).target == 0
                      ? 0
                      : balance.of(n).eaten / balance.of(n).target,
                  color: n.color,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// ป้ายสรุปว่ามื้อนี้ขาดหรือเกินอะไร
class BalanceChips extends StatelessWidget {
  const BalanceChips({super.key, required this.balance});

  final MealBalance balance;

  @override
  Widget build(BuildContext context) {
    final lacking = balance.lacking;
    final excess = balance.excess;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (lacking.isEmpty && excess.isEmpty)
          const _Chip(text: 'สมดุลดี', color: AppColors.lime),
        for (final b in lacking)
          _Chip(
            text:
                'ขาด${b.nutrient.label} ${(-b.diff).round()} ${b.nutrient.unit}',
            color: AppColors.carbs.withValues(alpha: 0.35),
          ),
        for (final b in excess)
          _Chip(
            text:
                '${b.nutrient.label}เกิน ${b.diff.round()} ${b.nutrient.unit}',
            color: AppColors.fat.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
