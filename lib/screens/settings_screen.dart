import 'package:flutter/material.dart';
import '../widgets/coming_soon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: const ComingSoon(
        icon: Icons.settings,
        text: 'تنظیمات صدا، ویبره و تایمر به‌زودی همینجا میاد.',
      ),
    );
  }
}
