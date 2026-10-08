import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ปุ่มไอคอนวงกลมสีขาว ใช้ที่หัวหน้าจอ
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * 0.45,
              color: onPressed == null ? AppColors.muted : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
