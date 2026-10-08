import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pill_progress_bar.dart';
import '../../../profile/domain/usecases/calculate_energy_needs.dart';
import '../../domain/entities/nutrients.dart';

/// การ์ดพลังงานของวัน: วงแหวน kcal ที่กินไปเทียบกับ TDEE
class EnergyRingCard extends StatelessWidget {
  const EnergyRingCard({
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProgressRing(
                  value: target == 0 ? 0 : consumed.kcal / target,
                  color: over ? AppColors.danger : AppColors.limeStrong,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF59E3B),
                      ),
                      Text(
                        '${consumed.kcal.round()}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เป้าหมาย',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        '${target.round()} kcal',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _Badge(
                        text: over
                            ? 'เกิน ${(-remaining).round()} kcal'
                            : 'เหลือ ${remaining.round()} kcal',
                        color: over
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : AppColors.lime,
                        textColor: over ? AppColors.danger : AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _Stat(label: 'BMR', value: '${needs.bmr.round()}'),
                  _Stat(label: 'BMI', value: needs.bmi.toStringAsFixed(1)),
                  _Stat(label: 'เกณฑ์', value: _bmiLabel(needs.bmi)),
                ],
              ),
            ),
            if (needs.isActivityAssumed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'ยังไม่ได้ระบุกิจกรรม คำนวณโดยถือว่าไม่ค่อยออกกำลังกาย',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleSmall),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
