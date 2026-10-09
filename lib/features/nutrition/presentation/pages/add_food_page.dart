import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/utils/thai_text.dart';
import '../../../../core/widgets/number_field.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_log_stats.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/remote_search_result.dart';
import '../../domain/usecases/meal_balance.dart';
import '../providers/nutrition_providers.dart';
import 'custom_ingredient_page.dart';
import 'scan_barcode_page.dart';

class AddFoodPage extends ConsumerStatefulWidget {
  const AddFoodPage({super.key, this.day, this.meal});

  /// วันที่จะบันทึก ถ้าเป็น null คือวันนี้
  final DateTime? day;

  /// มื้อเริ่มต้น ถ้าเป็น null จะเดาจากเวลาตอนนี้
  final Meal? meal;

  @override
  ConsumerState<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends ConsumerState<AddFoodPage> {
  late Meal _meal = widget.meal ?? Meal.fromTime(DateTime.now());

  DateTime? get day => widget.day;

  /// กำลังหาสินค้าจากบาร์โค้ดที่สแกน
  bool _lookingUp = false;

  /// [suggestedName] ใช้กับผลจาก USDA: ให้ตั้งชื่อไทยก่อนเก็บลงเครื่อง
  Future<void> _pick(Ingredient ingredient, {String? suggestedName}) async {
    final result = await showDialog<_PickResult>(
      context: context,
      builder: (_) =>
          _GramsDialog(ingredient: ingredient, suggestedName: suggestedName),
    );
    if (result == null) return;
    final grams = result.grams;
    if (result.name != null) ingredient = ingredient.withName(result.name!);
    if (ingredient.source
        case IngredientSource.usda || IngredientSource.openFoodFacts) {
      await ref.read(ingredientsProvider.notifier).save(ingredient);
    }
    await ref
        .read(foodLogProvider.notifier)
        .add(ingredient, grams, day: day, meal: _meal);
    if (mounted) Navigator.of(context).pop();
  }

  /// [barcode] ใส่เมื่อสแกนแล้วไม่พบสินค้า ให้ครั้งหน้าสแกนเจอวัตถุดิบที่กรอกไว้
  Future<void> _addCustom({String? barcode}) async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CustomIngredientPage(day: day, meal: _meal, barcode: barcode),
      ),
    );
    // บันทึกเข้ารายการแล้ว ไม่ต้องอยู่หน้าเลือกวัตถุดิบต่อ
    if (logged == true && mounted) Navigator.of(context).pop();
  }

  /// สแกนบาร์โค้ด เจอสินค้าก็ถามปริมาณเลย ไม่เจอก็เปิดหน้าเพิ่มวัตถุดิบใหม่
  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScanBarcodePage()));
    if (code == null || !mounted) return;

    setState(() => _lookingUp = true);
    final Ingredient? found;
    try {
      found = await ref.read(ingredientRepositoryProvider).lookupBarcode(code);
    } on IngredientSearchException catch (e) {
      _showMessage(switch (e) {
        RateLimitedException() => 'ค้นหาถี่เกินไป รอสักครู่แล้วลองใหม่',
        _ => 'เชื่อมต่อ Open Food Facts ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่',
      });
      return;
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
    if (!mounted) return;

    if (found == null) {
      _showMessage('ไม่พบข้อมูลโภชนาการของบาร์โค้ด $code กรอกค่าจากฉลากได้เลย');
      await _addCustom(barcode: code);
      return;
    }
    await _pick(
      found,
      // สินค้าส่วนใหญ่มีแต่ชื่ออังกฤษ ให้ตั้งชื่อไทยได้ก่อนเก็บลงเครื่อง
      suggestedName:
          found.source == IngredientSource.openFoodFacts &&
              !ThaiText.hasThai(found.name)
          ? ''
          : null,
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(ingredientQueryProvider).trim();
    final local = ref.watch(filteredIngredientsProvider);
    final usda = ref.watch(usdaSearchProvider);
    final theme = Theme.of(context);

    void searchUsda() => ref.read(usdaSearchProvider.notifier).search(query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกวัตถุดิบ'),
        actions: [
          IconButton(
            tooltip: 'สแกนบาร์โค้ด',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _lookingUp ? null : _scan,
          ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('วัตถุดิบใหม่'),
            onPressed: _addCustom,
          ),
        ],
        bottom: _lookingUp
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Column(
        children: [
          _MealPicker(
            selected: _meal,
            onChanged: (meal) => setState(() => _meal = meal),
          ),
          _MealGapBanner(day: day ?? DateTime.now(), meal: _meal),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาวัตถุดิบ (ไทยหรืออังกฤษ)',
                prefixIcon: Icon(Icons.search),
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
                              onTap: () => _pick(item),
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
                              onTap: () => _pick(
                                item,
                                // คำค้นภาษาไทยมักเป็นชื่อที่ user อยากเห็นอยู่แล้ว
                                suggestedName: ThaiText.hasThai(query)
                                    ? query
                                    : '',
                              ),
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

class _MealPicker extends StatelessWidget {
  const _MealPicker({required this.selected, required this.onChanged});

  final Meal selected;
  final ValueChanged<Meal> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          for (final meal in Meal.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(meal.label),
                selected: meal == selected,
                onSelected: (_) => onChanged(meal),
              ),
            ),
        ],
      ),
    );
  }
}

/// บอกว่ามื้อที่เลือกยังขาดอะไร ระหว่างเลือกวัตถุดิบจะได้เห็นเลย
class _MealGapBanner extends ConsumerWidget {
  const _MealGapBanner({required this.day, required this.meal});

  final DateTime day;
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayTarget = ref.watch(dayTargetProvider);
    if (dayTarget == null) return const SizedBox.shrink();
    final entries = (ref.watch(foodLogProvider).value ?? const <FoodEntry>[])
        .entriesOn(day.dateOnly);
    final balance = MealPlanner.balance(meal, dayTarget, entries);
    final lacking = balance.lacking;
    final kcalLeft = (balance.target.kcal - balance.eaten.kcal).round();
    final text = lacking.isEmpty
        ? (kcalLeft > 0
              ? '${meal.label}เหลืออีก $kcalLeft kcal'
              : '${meal.label}ครบเป้าแล้ว')
        : '${meal.label}ยังขาด: ${lacking.map((b) => '${b.nutrient.label} '
              '${(-b.diff).round()} ${b.nutrient.unit}').join(' · ')}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: lacking.isEmpty ? AppColors.soft : AppColors.lime,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
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
      IngredientSource.openFoodFacts => 'บาร์โค้ด',
    };
    final nameEn = ingredient.nameEn;
    // วัตถุดิบจาก USDA/บาร์โค้ดที่ตั้งชื่อไทยแล้ว แสดงชื่ออังกฤษเดิมกำกับไว้
    final showEnglish =
        ingredient.source != IngredientSource.builtin &&
        nameEn != null &&
        nameEn != ingredient.name;
    return ListTile(
      isThreeLine: showEnglish,
      title: Text(ingredient.name),
      subtitle: Text(
        '${showEnglish ? '$nameEn\n' : ''}'
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

typedef _PickResult = ({double grams, String? name});

class _GramsDialog extends StatefulWidget {
  const _GramsDialog({required this.ingredient, this.suggestedName});

  final Ingredient ingredient;

  /// ถ้าไม่เป็น null จะมีช่องให้ตั้งชื่อ (ใช้กับผลจาก USDA และบาร์โค้ด)
  final String? suggestedName;

  @override
  State<_GramsDialog> createState() => _GramsDialogState();
}

class _GramsDialogState extends State<_GramsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _grams = TextEditingController(text: '100');
  late final _name = TextEditingController(text: widget.suggestedName);

  @override
  void dispose() {
    _grams.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    Navigator.of(context).pop((
      grams: double.parse(_grams.text),
      // เว้นว่าง = ใช้ชื่อเดิมจาก USDA หรือ Open Food Facts
      name: widget.suggestedName == null || name.isEmpty ? null : name,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient.name),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.suggestedName != null) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อภาษาไทย (ไม่บังคับ)',
                  helperText: 'เว้นว่างไว้เพื่อใช้ชื่อเดิม',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
            ],
            NumberField(
              controller: _grams,
              label: 'ปริมาณ',
              suffix: 'กรัม',
              max: 5000,
              autofocus: widget.suggestedName == null,
            ),
          ],
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
