import 'package:flutter/material.dart';
import '../widgets/coming_soon.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه بازی‌ها')),
      body: const ComingSoon(
        icon: Icons.access_time,
        text: 'لیست بازی‌های تمام‌شده به‌زودی همینجا میاد.',
      ),
    );
  }
}
