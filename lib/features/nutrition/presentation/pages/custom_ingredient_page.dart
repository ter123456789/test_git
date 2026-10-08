import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/number_field.dart';
import '../../domain/entities/nutrients.dart';
import '../providers/nutrition_providers.dart';

class CustomIngredientPage extends ConsumerStatefulWidget {
  const CustomIngredientPage({super.key});

  @override
  ConsumerState<CustomIngredientPage> createState() =>
      _CustomIngredientPageState();
}

class _CustomIngredientPageState extends ConsumerState<CustomIngredientPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref
        .read(ingredientsProvider.notifier)
        .addCustom(
          name: _name.text.trim(),
          per100g: Nutrients(
            kcal: double.parse(_kcal.text),
            proteinG: double.parse(_protein.text),
            carbsG: double.parse(_carbs.text),
            fatG: double.parse(_fat.text),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มวัตถุดิบใหม่')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อวัตถุดิบ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'ค่าโภชนาการต่อ 100 กรัม',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              NumberField(
                controller: _kcal,
                label: 'พลังงาน',
                suffix: 'kcal',
                max: 900,
                allowZero: true,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _protein,
                label: 'โปรตีน',
                suffix: 'ก.',
                max: 100,
                allowZero: true,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _carbs,
                label: 'คาร์โบไฮเดรต',
                suffix: 'ก.',
                max: 100,
                allowZero: true,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _fat,
                label: 'ไขมัน',
                suffix: 'ก.',
                max: 100,
                allowZero: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
