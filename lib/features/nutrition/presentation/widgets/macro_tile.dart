import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pill_progress_bar.dart';

/// แถวสารอาหารหนึ่งชนิด: ไอคอนวงกลม ชื่อ ปริมาณ/เป้าหมาย และแถบความคืบหน้า
class MacroTile extends StatelessWidget {
  const MacroTile({
    super.key,
    required this.icon,
    required this.label,
    required this.grams,
    required this.targetGrams,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double grams;
  final double targetGrams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color.withValues(alpha: 1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: theme.textTheme.titleMedium),
                    ),
                    Text.rich(
                      TextSpan(
                        text: grams.toStringAsFixed(0),
                        style: theme.textTheme.titleMedium,
                        children: [
                          TextSpan(
                            text: ' / ${targetGrams.round()} ก.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PillProgressBar(
                  value: targetGrams == 0 ? 0 : grams / targetGrams,
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
