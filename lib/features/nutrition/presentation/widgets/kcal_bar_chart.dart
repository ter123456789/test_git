import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';

/// กราฟแท่งพลังงานรายวัน มีเส้นประบอกเป้าหมาย
///
/// แท่งที่เกินเป้าเป็นสีส้ม แท่งของ [selected] เป็นสีเข้ม
class KcalBarChart extends StatelessWidget {
  const KcalBarChart({
    super.key,
    required this.days,
    required this.target,
    this.selected,
    this.onSelect,
    this.height = 150,
    this.showLabels = true,
    this.barColor = AppColors.limeStrong,
  });

  final List<(DateTime, double)> days;
  final double target;
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;
  final double height;
  final bool showLabels;

  /// สีแท่งของวันที่ไม่เกินเป้า
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final maxKcal = days.fold<double>(
      target * 1.15,
      (m, d) => d.$2 > m ? d.$2 : m,
    );
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppColors.muted);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            children: [
              if (target > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * target / maxKcal,
                  child: const _DashedLine(),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (day, kcal) in days)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelect == null ? null : () => onSelect!(day),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 0.62,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              // แท่งของวันที่ไม่ได้บันทึกยังเห็นเป็นตอเล็ก ๆ
                              height: kcal == 0
                                  ? 6
                                  : (height * kcal / maxKcal).clamp(6, height),
                              decoration: BoxDecoration(
                                color: _barColor(day, kcal),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (day, _) in days)
                Expanded(
                  child: Text(
                    days.length > 7 ? '${day.day}' : ThaiDate.weekday(day),
                    textAlign: TextAlign.center,
                    style: selected != null && day.isSameDay(selected!)
                        ? labelStyle?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          )
                        : labelStyle,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _barColor(DateTime day, double kcal) {
    if (selected != null && day.isSameDay(selected!)) return AppColors.ink;
    if (kcal == 0) return AppColors.ink.withValues(alpha: 0.08);
    if (target > 0 && kcal > target) return AppColors.fat;
    return barColor;
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 5.0;
        final count = (c.maxWidth / (dash * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              Container(width: dash, height: 1.5, color: AppColors.muted),
          ],
        );
      },
    );
  }
}
