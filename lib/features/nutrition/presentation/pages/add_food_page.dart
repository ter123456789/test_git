import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/number_field.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/remote_search_result.dart';
import '../providers/nutrition_providers.dart';
import 'custom_ingredient_page.dart';

class AddFoodPage extends ConsumerWidget {
  const AddFoodPage({super.key});

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    final grams = await showDialog<double>(
      context: context,
      builder: (_) => _GramsDialog(ingredient: ingredient),
    );
    if (grams == null) return;
    if (ingredient.source == IngredientSource.usda) {
      await ref.read(ingredientsProvider.notifier).save(ingredient);
    }
    await ref.read(todayLogProvider.notifier).add(ingredient, grams);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(ingredientQueryProvider).trim();
    final local = ref.watch(filteredIngredientsProvider);
    final usda = ref.watch(usdaSearchProvider);
    final theme = Theme.of(context);

    void searchUsda() => ref.read(usdaSearchProvider.notifier).search(query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกวัตถุดิบ'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('วัตถุดิบใหม่'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CustomIngredientPage(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาวัตถุดิบ (ไทยหรืออังกฤษ)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (text) {
                ref.read(ingredientQueryProvider.notifier).set(text);
                ref.read(usdaSearchProvider.notifier).clear();
              },
              onSubmitted: (_) => searchUsda(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ...local.when(
                  loading: () => const [
                    Center(child: CircularProgressIndicator()),
                  ],
                  error: (e, _) => [
                    ListTile(title: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
                  ],
                  data: (items) => items.isEmpty
                      ? const [ListTile(title: Text('ไม่พบในรายการของคุณ'))]
                      : [
                          for (final item in items)
                            _IngredientTile(
                              ingredient: item,
                              onTap: () => _pick(context, ref, item),
                            ),
                        ],
                ),
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'จาก USDA FoodData Central',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                ...usda.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    ListTile(
                      leading: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(_errorMessage(e)),
                      trailing: e is UntranslatableQueryException
                          ? null
                          : TextButton(
                              onPressed: searchUsda,
                              child: const Text('ลองใหม่'),
                            ),
                    ),
                  ],
                  data: (result) => result == null
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: query.isEmpty
                                ? Text(
                                    'พิมพ์ชื่อวัตถุดิบแล้วกดค้นหา '
                                    'เพื่อหาเพิ่มจากฐานข้อมูล USDA',
                                    style: theme.textTheme.bodySmall,
                                  )
                                : OutlinedButton.icon(
                                    icon: const Icon(Icons.travel_explore),
                                    label: Text('ค้นหา "$query" จาก USDA'),
                                    onPressed: searchUsda,
                                  ),
                          ),
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Text(
                              'ค้นด้วยคำว่า "${result.query}" '
                              '· ${result.items.length} รายการ',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          for (final item in result.items)
                            _IngredientTile(
                              ingredient: item,
                              onTap: () => _pick(context, ref, item),
                            ),
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _errorMessage(Object error) => switch (error) {
    UntranslatableQueryException(:final query) =>
      'ไม่รู้จักคำว่า "$query" ลองพิมพ์เป็นภาษาอังกฤษ เช่น chicken breast',
    RateLimitedException() =>
      'ใช้โควตาค้นหาครบแล้ว (DEMO_KEY ได้ราว 10 ครั้ง/ชั่วโมง) '
          'ลองใหม่ภายหลัง หรือใช้ API key ของตัวเอง',
    RemoteUnavailableException() =>
      'เชื่อมต่อ USDA ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
    _ => 'ค้นหาไม่สำเร็จ: $error',
  };
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient, required this.onTap});

  final Ingredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = ingredient.per100g;
    final badge = switch (ingredient.source) {
      IngredientSource.builtin => null,
      IngredientSource.custom => 'เพิ่มเอง',
      IngredientSource.usda => 'USDA',
    };
    return ListTile(
      title: Text(ingredient.name),
      subtitle: Text(
        '${n.kcal.round()} kcal / 100 ก. · '
        'P ${n.proteinG.toStringAsFixed(1)} '
        'C ${n.carbsG.toStringAsFixed(1)} '
        'F ${n.fatG.toStringAsFixed(1)}',
      ),
      trailing: badge == null ? null : Chip(label: Text(badge)),
      onTap: onTap,
    );
  }
}

class _GramsDialog extends StatefulWidget {
  const _GramsDialog({required this.ingredient});

  final Ingredient ingredient;

  @override
  State<_GramsDialog> createState() => _GramsDialogState();
}

class _GramsDialogState extends State<_GramsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _grams = TextEditingController(text: '100');

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(double.parse(_grams.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient.name),
      content: Form(
        key: _formKey,
        child: NumberField(
          controller: _grams,
          label: 'ปริมาณ',
          suffix: 'กรัม',
          max: 5000,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('เพิ่ม')),
      ],
    );
  }
}
