import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_log_stats.dart';
import '../../domain/entities/nutrients.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/food_entry_tile.dart';
import '../widgets/kcal_bar_chart.dart';
import 'add_food_page.dart';

/// ประวัติการกินย้อนหลัง: เลือกวันจากแถบสัปดาห์ ดูสรุปและรายการของวันนั้น
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late DateTime _selected = DateTime.now().dateOnly;

  DateTime get _today => DateTime.now().dateOnly;

  /// วันอาทิตย์ของสัปดาห์ที่มี [day]
  static DateTime _weekStart(DateTime day) =>
      DateTime(day.year, day.month, day.day - day.weekday % 7);

  void _select(DateTime day) {
    if (day.isAfter(_today)) return;
    setState(() => _selected = day.dateOnly);
  }

  void _shiftWeek(int weeks) {
    final next = DateTime(
      _selected.year,
      _selected.month,
      _selected.day + 7 * weeks,
    );
    _select(next.isAfter(_today) ? _today : next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = ref.watch(energyNeedsProvider)?.tdee ?? 0;
    final all = ref.watch(foodLogProvider).value ?? const <FoodEntry>[];
    final entries = all.entriesOn(_selected);
    final totals = all.totalsOn(_selected);
    final previous = all.totalsOn(
      DateTime(_selected.year, _selected.month, _selected.day - 1),
    );
    final trend = all.dailyKcal(end: _selected, days: 14);
    final weekStart = _weekStart(_selected);
    final isCurrentWeek = !_weekStart(_today).isAfter(weekStart);

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
        title: const Text('ประวัติการกิน'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 40,
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AddFoodPage(day: _selected),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _selected == _today
                ? 'เพิ่มวัตถุดิบ'
                : 'เพิ่มย้อนหลัง ${ThaiDate.short(_selected)}',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ThaiDate.monthYear(_selected),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              RoundIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'สัปดาห์ก่อน',
                size: 40,
                onPressed: () => _shiftWeek(-1),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'สัปดาห์ถัดไป',
                size: 40,
                onPressed: isCurrentWeek ? null : () => _shiftWeek(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeekStrip(
            start: weekStart,
            selected: _selected,
            today: _today,
            logged: all.loggedDays,
            onSelect: _select,
          ),
          const SizedBox(height: 20),
          _DaySummaryCard(
            day: _selected,
            totals: totals,
            previous: previous,
            target: target,
            trend: trend,
            onSelect: _select,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected == _today
                      ? 'รายการวันนี้'
                      : 'รายการ${ThaiDate.long(_selected)}',
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
          FoodEntryList(
            entries: entries,
            emptyText: 'ไม่มีการบันทึกในวันนี้',
            onDelete: (e) => ref.read(foodLogProvider.notifier).remove(e.id),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.today,
    required this.logged,
    required this.onSelect,
  });

  final DateTime start;
  final DateTime selected;
  final DateTime today;
  final Set<DateTime> logged;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final day = DateTime(start.year, start.month, start.day + i);
                final isSelected = day == selected;
                final isFuture = day.isAfter(today);
                final hasLog = logged.contains(day);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isFuture ? null : () => onSelect(day),
                  child: Column(
                    children: [
                      Text(
                        ThaiDate.weekday(day),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppColors.ink : AppColors.muted,
                          fontWeight: isSelected ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.ink
                              : AppColors.surface.withValues(
                                  alpha: isFuture ? 0.4 : 1,
                                ),
                          border: day == today && !isSelected
                              ? Border.all(
                                  color: AppColors.limeStrong,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                ? AppColors.muted
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasLog
                              ? AppColors.limeStrong
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// สรุปของวันที่เลือก + กราฟ 14 วันย้อนหลัง (กดแท่งเพื่อเปลี่ยนวัน)
class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.day,
    required this.totals,
    required this.previous,
    required this.target,
    required this.trend,
    required this.onSelect,
  });

  final DateTime day;
  final Nutrients totals;
  final Nutrients previous;
  final double target;
  final List<(DateTime, double)> trend;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = target == 0 ? 0 : (totals.kcal / target * 100).round();
    final diff = totals.kcal - previous.kcal;
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6FBD9), AppColors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ThaiDate.long(day), style: muted),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text.rich(
                    TextSpan(
                      text: '${totals.kcal.round()}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      children: [TextSpan(text: ' kcal', style: muted)],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: ShapeDecoration(
                  color: percent > 110
                      ? AppColors.fat.withValues(alpha: 0.3)
                      : AppColors.lime,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '$percent% ของเป้า',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          KcalBarChart(
            days: trend,
            target: target,
            selected: day,
            onSelect: onSelect,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  value: previous.kcal == 0
                      ? '–'
                      : '${diff >= 0 ? '+' : ''}${diff.round()}',
                  label: 'kcal เทียบกับวันก่อน',
                ),
              ),
              Expanded(
                child: _Figure(
                  value:
                      'P ${totals.proteinG.round()} · C ${totals.carbsG.round()} · F ${totals.fatG.round()}',
                  label: 'สารอาหาร (กรัม)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
