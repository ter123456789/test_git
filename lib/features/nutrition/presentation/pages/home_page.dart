import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../profile/presentation/pages/profile_form_page.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_log_stats.dart';
import '../../domain/entities/nutrients.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/energy_ring_card.dart';
import '../widgets/food_entry_tile.dart';
import '../widgets/kcal_bar_chart.dart';
import '../widgets/macro_targets.dart';
import '../widgets/macro_tile.dart';
import 'add_food_page.dart';
import 'history_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static String _greeting(DateTime now) => switch (now.hour) {
    < 11 => 'อรุณสวัสดิ์',
    < 17 => 'สวัสดีตอนบ่าย',
    _ => 'สวัสดีตอนเย็น',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = now.dateOnly;
    final profile = ref.watch(profileProvider).value;
    final needs = ref.watch(energyNeedsProvider);
    final log = ref.watch(foodLogProvider);
    final all = log.value ?? const <FoodEntry>[];
    final entries = all.entriesOn(today);
    final totals = all.totalsOn(today);
    final week = all.dailyKcal(end: today);
    final theme = Theme.of(context);

    void openHistory() => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HistoryPage()));

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 40,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AddFoodPage())),
          icon: const Icon(Icons.add_rounded),
          label: const Text('เพิ่มวัตถุดิบ'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.lime,
                  child: Icon(Icons.eco_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(now), style: theme.textTheme.titleMedium),
                      Text(
                        ThaiDate.long(now),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.calendar_month_rounded,
                  tooltip: 'ประวัติการกิน',
                  onPressed: openHistory,
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'แก้ไขข้อมูลส่วนตัว',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileFormPage(initial: profile),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('โภชนาการวันนี้', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (needs != null) ...[
              EnergyRingCard(needs: needs, consumed: totals),
              const SizedBox(height: 12),
              ..._macroTiles(totals, macroTargetsFor(needs.tdee)),
              const SizedBox(height: 12),
              _WeekCard(days: week, target: needs.tdee, onTap: openHistory),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'รายการที่กินวันนี้',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    '${entries.length} รายการ',
                    style: const TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            log.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('โหลดข้อมูลไม่สำเร็จ: $e'),
              data: (_) => FoodEntryList(
                entries: entries.reversed.toList(),
                emptyText:
                    'ยังไม่มีรายการ\nกด "เพิ่มวัตถุดิบ" เพื่อเริ่มบันทึก',
                onDelete: (e) =>
                    ref.read(foodLogProvider.notifier).remove(e.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _macroTiles(Nutrients totals, Nutrients targets) => [
    for (final (icon, label, grams, target, color) in [
      (
        Icons.egg_alt_rounded,
        'โปรตีน',
        totals.proteinG,
        targets.proteinG,
        AppColors.protein,
      ),
      (
        Icons.rice_bowl_rounded,
        'คาร์บ',
        totals.carbsG,
        targets.carbsG,
        AppColors.carbs,
      ),
      (
        Icons.water_drop_rounded,
        'ไขมัน',
        totals.fatG,
        targets.fatG,
        AppColors.fat,
      ),
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MacroTile(
          icon: icon,
          label: label,
          grams: grams,
          targetGrams: target,
          color: color,
        ),
      ),
  ];
}

/// การ์ดสรุป 7 วันล่าสุด กดแล้วไปหน้าประวัติ
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.days,
    required this.target,
    required this.onTap,
  });

  final List<(DateTime, double)> days;
  final double target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logged = days.where((d) => d.$2 > 0).toList();
    final avg = logged.isEmpty
        ? 0
        : logged.fold<double>(0, (s, d) => s + d.$2) / logged.length;
    final onTarget = logged
        .where((d) => d.$2 >= target * 0.9 && d.$2 <= target * 1.1)
        .length;

    return Material(
      color: AppColors.lime,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '7 วันที่ผ่านมา',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'เฉลี่ย '),
                    TextSpan(
                      text: '${avg.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' · ตรงเป้า $onTarget จาก 7 วัน'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              KcalBarChart(
                days: days,
                target: target,
                selected: days.last.$1,
                height: 90,
                barColor: AppColors.protein,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
