import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/pages/profile_form_page.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/energy_summary_card.dart';
import 'add_food_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final needs = ref.watch(energyNeedsProvider);
    final log = ref.watch(todayLogProvider);
    final totals = ref.watch(todayTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('โภชนาการวันนี้'),
        actions: [
          IconButton(
            tooltip: 'แก้ไขข้อมูลส่วนตัว',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileFormPage(initial: profile),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AddFoodPage())),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มวัตถุดิบ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (needs != null) EnergySummaryCard(needs: needs, consumed: totals),
          const SizedBox(height: 16),
          Text(
            'รายการที่กินวันนี้',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...log.when(
            loading: () => const [Center(child: CircularProgressIndicator())],
            error: (e, _) => [Text('โหลดข้อมูลไม่สำเร็จ: $e')],
            data: (entries) => entries.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('ยังไม่มีรายการ กด + เพื่อเพิ่ม'),
                      ),
                    ),
                  ]
                : [
                    for (final e in entries.reversed)
                      Card(
                        child: ListTile(
                          title: Text(e.ingredient.name),
                          subtitle: Text(
                            '${e.grams.toStringAsFixed(0)} ก. · '
                            'P ${e.nutrients.proteinG.toStringAsFixed(1)} '
                            'C ${e.nutrients.carbsG.toStringAsFixed(1)} '
                            'F ${e.nutrients.fatG.toStringAsFixed(1)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${e.nutrients.kcal.round()} kcal'),
                              IconButton(
                                tooltip: 'ลบ',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref
                                    .read(todayLogProvider.notifier)
                                    .remove(e.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
