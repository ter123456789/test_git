import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/number_field.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
    ActivityLevel.sedentary => 'นั่งทำงาน ไม่ค่อยออกกำลังกาย',
    ActivityLevel.light => 'ออกกำลังกายเบา ๆ 1-3 วัน/สัปดาห์',
    ActivityLevel.moderate => 'ออกกำลังกายปานกลาง 3-5 วัน/สัปดาห์',
    ActivityLevel.active => 'ออกกำลังกายหนัก 6-7 วัน/สัปดาห์',
    ActivityLevel.veryActive => 'ใช้แรงงานหนัก หรือฝึกวันละ 2 ครั้ง',
  };
}

/// ใช้ทั้งตอนเข้าใช้งานครั้งแรก ([initial] เป็น null) และตอนแก้ไขโปรไฟล์
class ProfileFormPage extends ConsumerStatefulWidget {
  const ProfileFormPage({super.key, this.initial});

  final UserProfile? initial;

  @override
  ConsumerState<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends ConsumerState<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _weight = TextEditingController(
    text: _text(widget.initial?.weightKg),
  );
  late final _height = TextEditingController(
    text: _text(widget.initial?.heightCm),
  );
  late final _age = TextEditingController(text: _text(widget.initial?.age));
  late Sex? _sex = widget.initial?.sex;
  late ActivityLevel? _activity = widget.initial?.activityLevel;
  bool _saving = false;

  static String _text(num? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (_sex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเพศ')));
      return;
    }
    if (!formValid) return;

    setState(() => _saving = true);
    final profile = UserProfile(
      weightKg: double.parse(_weight.text),
      heightCm: double.parse(_height.text),
      age: int.parse(_age.text),
      sex: _sex!,
      activityLevel: _activity,
    );
    await ref.read(profileProvider.notifier).save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    // ตอนเข้าใช้งานครั้งแรกหน้านี้เป็นหน้าแรก ไม่มีหน้าให้ย้อนกลับ
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isOnboarding = widget.initial == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOnboarding ? 'ข้อมูลของคุณ' : 'แก้ไขข้อมูลส่วนตัว'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isOnboarding) ...[
                Text(
                  'กรอกข้อมูลเพื่อคำนวณพลังงานที่ร่างกายต้องการในแต่ละวัน',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
              ],
              NumberField(
                controller: _weight,
                label: 'น้ำหนัก',
                suffix: 'กก.',
                min: 20,
                max: 300,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _height,
                label: 'ส่วนสูง',
                suffix: 'ซม.',
                min: 80,
                max: 250,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _age,
                label: 'อายุ',
                suffix: 'ปี',
                min: 10,
                max: 120,
                allowDecimal: false,
              ),
              const SizedBox(height: 16),
              Text('เพศ', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(value: Sex.male, label: Text('ชาย')),
                  ButtonSegment(value: Sex.female, label: Text('หญิง')),
                ],
                selected: {?_sex},
                emptySelectionAllowed: true,
                onSelectionChanged: (s) =>
                    setState(() => _sex = s.isEmpty ? null : s.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityLevel?>(
                initialValue: _activity,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'กิจกรรมประจำวัน (ไม่บังคับ)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ไม่ระบุ')),
                  for (final level in ActivityLevel.values)
                    DropdownMenuItem(value: level, child: Text(level.label)),
                ],
                onChanged: (v) => setState(() => _activity = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(isOnboarding ? 'เริ่มใช้งาน' : 'บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
