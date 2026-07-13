import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HiddenRoleApp());
}

class HiddenRoleApp extends StatelessWidget {
  const HiddenRoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نقش پنهان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGoldTheme,
      // کل اپ همیشه راست‌به‌چپه، صرف‌نظر از لوکیل سیستم
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
