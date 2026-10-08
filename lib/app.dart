import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/nutrition/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_form_page.dart';
import 'features/profile/presentation/providers/profile_providers.dart';

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prachaya Healthy Body',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const _StartGate(),
    );
  }
}

/// ถ้ายังไม่มีโปรไฟล์ให้กรอกข้อมูลก่อน ไม่งั้นเข้าหน้าหลัก
class _StartGate extends ConsumerWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(profileProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              Scaffold(body: Center(child: Text('โหลดข้อมูลไม่สำเร็จ: $e'))),
          data: (profile) =>
              profile == null ? const ProfileFormPage() : const HomePage(),
        );
  }
}
