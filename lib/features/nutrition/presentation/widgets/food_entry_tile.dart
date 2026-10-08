import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../domain/entities/food_entry.dart';

/// รายการอาหารหนึ่งแถว: เวลา ชื่อ ปริมาณ/สารอาหาร พลังงาน และปุ่มลบ
class FoodEntryTile extends StatelessWidget {
  const FoodEntryTile({super.key, required this.entry, required this.onDelete});

  final FoodEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = entry.nutrients;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: ShapeDecoration(
              color: AppColors.soft,
              shape: const StadiumBorder(),
            ),
            alignment: Alignment.center,
            child: Text(
              ThaiDate.time(entry.eatenAt),
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.ingredient.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.grams.toStringAsFixed(0)} ก. · '
                  'P ${n.proteinG.toStringAsFixed(1)} '
                  'C ${n.carbsG.toStringAsFixed(1)} '
                  'F ${n.fatG.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text('${n.kcal.round()} kcal', style: theme.textTheme.titleSmall),
          IconButton(
            tooltip: 'ลบ',
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.muted,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// กล่องรวมรายการอาหาร หรือข้อความเมื่อยังไม่มีรายการ
class FoodEntryList extends StatelessWidget {
  const FoodEntryList({
    super.key,
    required this.entries,
    required this.onDelete,
    required this.emptyText,
  });

  final List<FoodEntry> entries;
  final ValueChanged<FoodEntry> onDelete;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.limeStrong,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final e in entries)
                  FoodEntryTile(entry: e, onDelete: () => onDelete(e)),
              ],
            ),
    );
  }
}
