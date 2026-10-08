import 'package:flutter/material.dart';

import '../../../profile/domain/usecases/calculate_energy_needs.dart';
import '../../domain/entities/nutrients.dart';

class EnergySummaryCard extends StatelessWidget {
  const EnergySummaryCard({
    super.key,
    required this.needs,
    required this.consumed,
  });

  final EnergyNeeds needs;
  final Nutrients consumed;

  /// เกณฑ์ BMI สำหรับคนเอเชีย (WHO Asia-Pacific)
  static String _bmiLabel(double bmi) => switch (bmi) {
    < 18.5 => 'น้ำหนักน้อย',
    < 23 => 'ปกติ',
    < 25 => 'น้ำหนักเกิน',
    _ => 'อ้วน',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = needs.tdee;
    final remaining = target - consumed.kcal;
    final over = remaining < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('พลังงานวันนี้', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${consumed.kcal.round()} / ${target.round()} kcal',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: target == 0 ? 0 : (consumed.kcal / target).clamp(0, 1),
              color: over ? theme.colorScheme.error : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              over
                  ? 'เกินเป้าหมาย ${(-remaining).round()} kcal'
                  : 'เหลืออีก ${remaining.round()} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: over ? theme.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Macro(label: 'โปรตีน', grams: consumed.proteinG),
                _Macro(label: 'คาร์บ', grams: consumed.carbsG),
                _Macro(label: 'ไขมัน', grams: consumed.fatG),
              ],
            ),
            const Divider(height: 24),
            Text(
              'BMR ${needs.bmr.round()} kcal · '
              'BMI ${needs.bmi.toStringAsFixed(1)} (${_bmiLabel(needs.bmi)})',
              style: theme.textTheme.bodySmall,
            ),
            if (needs.isActivityAssumed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'ยังไม่ได้ระบุกิจกรรม คำนวณโดยถือว่าไม่ค่อยออกกำลังกาย',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.grams});

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            '${grams.toStringAsFixed(1)} ก.',
            style: theme.textTheme.titleMedium,
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
