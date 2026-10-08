import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/number_field.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/entities/remote_search_result.dart';
import '../providers/nutrition_providers.dart';

/// เพิ่มวัตถุดิบใหม่: ใส่ชื่อกับน้ำหนัก แล้วแอปหาค่าโภชนาการมาเติมให้
///
/// pop กลับด้วย true เมื่อบันทึกเข้ารายการที่กินแล้ว
class CustomIngredientPage extends ConsumerStatefulWidget {
  const CustomIngredientPage({super.key, this.day});

  /// วันที่จะบันทึก ถ้าเป็น null คือวันนี้
  final DateTime? day;

  @override
  ConsumerState<CustomIngredientPage> createState() =>
      _CustomIngredientPageState();
}

class _CustomIngredientPageState extends ConsumerState<CustomIngredientPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  bool _saving = false;

  /// วัตถุดิบที่ใช้เติมค่าล่าสุด และตัวเลขที่เติมไป (ใช้ดูว่า user แก้เองหรือยัง)
  Ingredient? _filledFrom;
  List<String> _filledTexts = const [];

  bool get _editedByUser =>
      !listEquals(_nutrientFields.map((c) => c.text).toList(), _filledTexts);

  List<TextEditingController> get _nutrientFields => [
    _kcal,
    _protein,
    _carbs,
    _fat,
  ];

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onNameFocusChange);
    // ตัวเลขสรุปตามน้ำหนักต้องอัปเดตเมื่อแก้ค่า
    for (final c in [_grams, ..._nutrientFields]) {
      c.addListener(() => setState(() {}));
    }
  }

  /// ค้นเมื่อพิมพ์ชื่อเสร็จแล้วแตะออกจากช่อง (ไม่ค้นทุกตัวอักษร เพื่อประหยัดโควตา USDA)
  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus) _lookup();
  }

  @override
  void dispose() {
    // ถอดก่อน ไม่งั้นตอนปิดหน้าโฟกัสหลุดแล้วไปค้นหลัง widget ถูกทิ้ง
    _nameFocus.removeListener(_onNameFocusChange);
    for (final c in [_name, _grams, ..._nutrientFields]) {
      c.dispose();
    }
    _nameFocus.dispose();
    super.dispose();
  }

  void _lookup() =>
      ref.read(nutritionLookupProvider.notifier).lookup(_name.text);

  void _fillFrom(Ingredient source) {
    final n = source.per100g;
    _kcal.text = _fmt(n.kcal);
    _protein.text = _fmt(n.proteinG);
    _carbs.text = _fmt(n.carbsG);
    _fat.text = _fmt(n.fatG);
    setState(() {
      _filledFrom = source;
      _filledTexts = _nutrientFields.map((c) => c.text).toList();
    });
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Nutrients? get _per100g {
    final values = _nutrientFields.map((c) => double.tryParse(c.text));
    if (values.any((v) => v == null)) return null;
    final [kcal, protein, carbs, fat] = values.nonNulls.toList();
    return Nutrients(kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat);
  }

  Future<void> _submit({required bool addToLog}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ingredient = await ref
        .read(ingredientsProvider.notifier)
        .addCustom(
          name: _name.text.trim(),
          per100g: _per100g!,
          nameEn: _filledFrom?.nameEn,
        );
    if (addToLog) {
      await ref
          .read(foodLogProvider.notifier)
          .add(ingredient, double.parse(_grams.text), day: widget.day);
    }
    if (mounted) Navigator.of(context).pop(addToLog);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookup = ref.watch(nutritionLookupProvider);

    // เติมค่าจากตัวเลือกแรกให้อัตโนมัติเมื่อค้นเสร็จ
    ref.listen(nutritionLookupProvider, (_, next) {
      final first = next.value?.candidates.firstOrNull;
      if (first != null) _fillFrom(first);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มวัตถุดิบใหม่')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                focusNode: _nameFocus,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'ชื่อวัตถุดิบ',
                  hintText: 'เช่น อกไก่ ข้าวกล้อง กล้วยหอม',
                  suffixIcon: IconButton(
                    tooltip: 'หาค่าโภชนาการ',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: _lookup,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _lookup(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _grams,
                label: 'ปริมาณที่กิน',
                suffix: 'กรัม',
                max: 5000,
              ),
              const SizedBox(height: 16),
              _LookupStatus(
                lookup: lookup,
                selected: _editedByUser ? null : _filledFrom,
                onRetry: _lookup,
                onPick: _fillFrom,
              ),
              const SizedBox(height: 16),
              Text(
                'ค่าโภชนาการต่อ 100 กรัม',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _nutrientField(_kcal, 'พลังงาน', 'kcal', 900),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _nutrientField(_protein, 'โปรตีน', 'ก.', 100),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _nutrientField(_carbs, 'คาร์บ', 'ก.', 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _nutrientField(_fat, 'ไขมัน', 'ก.', 100)),
                ],
              ),
              const SizedBox(height: 16),
              _PortionSummary(
                per100g: _per100g,
                grams: double.tryParse(_grams.text),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : () => _submit(addToLog: true),
                child: const Text('บันทึกและเพิ่มในรายการที่กิน'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _saving ? null : () => _submit(addToLog: false),
                child: const Text('เก็บเป็นวัตถุดิบอย่างเดียว'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutrientField(
    TextEditingController controller,
    String label,
    String suffix,
    double max,
  ) => NumberField(
    controller: controller,
    label: label,
    suffix: suffix,
    max: max,
    allowZero: true,
  );
}

/// สถานะการหาค่าโภชนาการ และปุ่มเลือกผลอื่น
class _LookupStatus extends StatelessWidget {
  const _LookupStatus({
    required this.lookup,
    required this.selected,
    required this.onRetry,
    required this.onPick,
  });

  final AsyncValue<NutritionLookupResult?> lookup;
  final Ingredient? selected;
  final VoidCallback onRetry;
  final ValueChanged<Ingredient> onPick;

  @override
  Widget build(BuildContext context) {
    return lookup.when(
      loading: () => const _StatusBox(
        icon: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        text: 'กำลังหาค่าโภชนาการ...',
      ),
      error: (e, _) => _StatusBox(
        icon: const Icon(Icons.info_outline_rounded, color: AppColors.muted),
        text: '${_errorMessage(e)} กรอกค่าเองได้เลย',
        action: e is UntranslatableQueryException
            ? null
            : TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
      ),
      data: (result) {
        if (result == null) {
          return const _StatusBox(
            icon: Icon(Icons.auto_awesome_rounded, color: AppColors.limeStrong),
            text: 'ใส่ชื่อแล้วกดค้นหา แอปจะเติมค่าโภชนาการให้',
          );
        }
        if (result.candidates.isEmpty) {
          return const _StatusBox(
            icon: Icon(Icons.search_off_rounded, color: AppColors.muted),
            text: 'ไม่พบข้อมูล กรอกค่าเองได้เลย',
          );
        }
        final others = result.candidates.length - 1;
        return _StatusBox(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.limeStrong,
          ),
          text: selected == null
              ? 'แก้ค่าเองแล้ว'
              : 'ใช้ค่าจาก: ${selected!.name}'
                    '${selected!.source == IngredientSource.usda ? ' (USDA)' : ''}',
          action: others > 0
              ? TextButton(
                  onPressed: () => _showCandidates(context, result.candidates),
                  child: Text('เลือกอื่น ($others)'),
                )
              : null,
        );
      },
    );
  }

  Future<void> _showCandidates(
    BuildContext context,
    List<Ingredient> candidates,
  ) async {
    final picked = await showModalBottomSheet<Ingredient>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in candidates)
              ListTile(
                title: Text(c.name),
                subtitle: Text(
                  '${c.per100g.kcal.round()} kcal / 100 ก. · '
                  'P ${c.per100g.proteinG.toStringAsFixed(1)} '
                  'C ${c.per100g.carbsG.toStringAsFixed(1)} '
                  'F ${c.per100g.fatG.toStringAsFixed(1)}',
                ),
                trailing: c == selected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPick(picked);
  }

  static String _errorMessage(Object error) => switch (error) {
    UntranslatableQueryException() => 'ยังไม่รู้จักชื่อนี้',
    RateLimitedException() => 'ใช้โควตาค้นหา USDA ครบแล้ว',
    RemoteUnavailableException() => 'เชื่อมต่อ USDA ไม่ได้',
    _ => 'หาค่าโภชนาการไม่สำเร็จ',
  };
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.icon, required this.text, this.action});

  final Widget icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          ?action,
        ],
      ),
    );
  }
}

/// ค่าโภชนาการตามน้ำหนักที่กินจริง
class _PortionSummary extends StatelessWidget {
  const _PortionSummary({required this.per100g, required this.grams});

  final Nutrients? per100g;
  final double? grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grams = this.grams;
    final n = (per100g == null || grams == null || grams <= 0)
        ? null
        : per100g!.scale(grams / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(20),
      ),
      child: n == null
          ? const Text('กรอกน้ำหนักและค่าโภชนาการให้ครบเพื่อดูสรุป')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${grams!.round()} กรัม = ${n.kcal.round()} kcal',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'โปรตีน ${n.proteinG.toStringAsFixed(1)} ก. · '
                  'คาร์บ ${n.carbsG.toStringAsFixed(1)} ก. · '
                  'ไขมัน ${n.fatG.toStringAsFixed(1)} ก.',
                ),
              ],
            ),
    );
  }
}
