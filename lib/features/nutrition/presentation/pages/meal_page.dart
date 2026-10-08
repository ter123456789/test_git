import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/widgets/pill_progress_bar.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../data/datasources/thai_availability.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_log_stats.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/meal.dart';
import '../../domain/usecases/meal_balance.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/food_entry_tile.dart';
import '../widgets/meal_section.dart';
import 'add_food_page.dart';

/// รายละเอียดของมื้อ: เทียบกับเป้า บอกว่าขาดอะไร และแนะนำของที่ควรกินเพิ่ม
class MealPage extends ConsumerWidget {
  const MealPage({super.key, required this.day, required this.meal});

  final DateTime day;
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayEntries = (ref.watch(foodLogProvider).value ?? const <FoodEntry>[])
        .entriesOn(day);
    final entries = dayEntries.where((e) => e.meal == meal).toList();
    final dayTarget = ref.watch(dayTargetProvider);
    final balance = dayTarget == null
        ? null
        : MealPlanner.balance(meal, dayTarget, dayEntries);
    final ingredients = ref.watch(ingredientsProvider).value ?? const [];
    final suggestions = balance == null
        ? const <FoodSuggestion>[]
        : MealPlanner.suggest(
            balance,
            ingredients.where(ThaiAvailability.isEasyToFind),
          );

    Future<void> addSuggestion(FoodSuggestion s) async {
      await ref
          .read(foodLogProvider.notifier)
          .add(s.ingredient, s.grams, day: day, meal: meal);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่ม${s.ingredient.name} ${s.grams.round()} ก. แล้ว',
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'ย้อนกลับ',
              size: 44,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(meal.label),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 40,
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AddFoodPage(day: day, meal: meal),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text('เพิ่มใน${meal.label}'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        children: [
          Text(
            ThaiDate.long(day),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (balance != null) ...[
            _BalanceCard(balance: balance),
            const SizedBox(height: 20),
            Text('ควรกินอะไรเพิ่ม', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _Advice(
              balance: balance,
              suggestions: suggestions,
              onAdd: addSuggestion,
            ),
            const SizedBox(height: 24),
          ],
          Text('รายการใน${meal.label}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          FoodEntryList(
            entries: entries,
            emptyText: 'ยังไม่มีรายการในมื้อนี้',
            onDelete: (e) => ref.read(foodLogProvider.notifier).remove(e.id),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final MealBalance balance;

  static String _status(NutrientBalance b) => switch (b.status) {
    BalanceStatus.low => 'ขาด ${(-b.diff).round()} ${b.nutrient.unit}',
    BalanceStatus.high => 'เกิน ${b.diff.round()} ${b.nutrient.unit}',
    BalanceStatus.ok => 'พอดี',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final b in balance.items) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.nutrient.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${b.eaten.round()} / ${b.target.round()} '
                    '${b.nutrient.unit}',
                    style: muted,
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 76,
                    child: Text(
                      _status(b),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: switch (b.status) {
                          BalanceStatus.low => const Color(0xFFB7861A),
                          BalanceStatus.high => AppColors.danger,
                          BalanceStatus.ok => AppColors.protein,
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PillProgressBar(
                value: b.target == 0 ? 0 : b.eaten / b.target,
                color: b.nutrient.color,
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'เป้าของมื้อคิดจากที่เหลือของวัน ถ้าข้ามมื้อก่อนหน้า '
              'เป้ามื้อนี้จะเพิ่มขึ้น ถ้ามื้อก่อนหน้ากินเกิน เป้าจะลดลง',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({
    required this.balance,
    required this.suggestions,
    required this.onAdd,
  });

  final MealBalance balance;
  final List<FoodSuggestion> suggestions;
  final ValueChanged<FoodSuggestion> onAdd;

  static const _cutTips = {
    Nutrient.kcal: 'มื้อถัดไปเลือกจานเล็กลง หรือเน้นผักและโปรตีนไม่ติดมัน',
    Nutrient.protein:
        'โปรตีนเกินไม่อันตรายในมื้อเดียว แต่มื้อถัดไปลดเนื้อสัตว์ลงได้',
    Nutrient.carbs: 'มื้อถัดไปลดข้าว เส้น ขนมปัง หรือของหวานลง',
    Nutrient.fat: 'มื้อถัดไปเลือกแบบต้ม นึ่ง ย่าง แทนทอดหรือผัดน้ำมันเยอะ',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final need = balance.lacking.firstOrNull;
    final excess = balance.excess;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (need == null && excess.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('มื้อนี้สมดุลดีแล้ว ไม่ต้องเพิ่มอะไร'),
            ),
          if (need != null) ...[
            Text(
              'ยังขาด ${balance.lacking.map((b) => '${b.nutrient.label} '
                  '${(-b.diff).round()} ${b.nutrient.unit}').join(' · ')}\n'
              'ลองเพิ่มอย่างใดอย่างหนึ่ง',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              'เลือกจากวัตถุดิบที่หาง่ายในไทย',
              style: theme.textTheme.bodySmall,
            ),
            if (suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'ไม่มีวัตถุดิบในเครื่องที่เหมาะ ลองค้นจาก USDA ในหน้าเพิ่มวัตถุดิบ',
                ),
              ),
            for (final s in suggestions) _SuggestionTile(s: s, onAdd: onAdd),
          ],
          for (final b in excess)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
              child: Text(
                '${b.nutrient.label}เกิน ${b.diff.round()} ${b.nutrient.unit}: '
                '${_cutTips[b.nutrient]}',
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.s, required this.onAdd});

  final FoodSuggestion s;
  final ValueChanged<FoodSuggestion> onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adds = s.adds;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.ingredient.name} ${s.grams.round()} ก.',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '+${s.fills.of(adds).round()} ${s.fills.unit} ${s.fills.label}'
                  ' · ${adds.kcal.round()} kcal'
                  '${s.ingredient.source == IngredientSource.usda ? ' · USDA' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              // ธีมตั้งปุ่มให้เต็มความกว้าง ใช้ในแถวไม่ได้
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => onAdd(s),
            child: const Text('+ เพิ่ม'),
          ),
        ],
      ),
    );
  }
}
