import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یه ویجت مشترک برای صفحاتی که هنوز منطقشون ساخته نشده.
class ComingSoon extends StatelessWidget {
  final IconData icon;
  final String text;
  const ComingSoon({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.gold.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
