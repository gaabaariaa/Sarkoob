import 'package:flutter/material.dart';
import 'game_3d_button.dart';

/// یکی از ۶ کارت منوی صفحه‌ی اصلی (شروع بازی، بازیکنان، آمار، ...).
/// این نشست از ظاهرِ تختِ قدیمی به ظاهرِ سه‌بعدیِ برجسته تغییر کرد —
/// پیاده‌سازیِ واقعی حالا تو Game3DTile (widgets/game_3d_button.dart)ه؛
/// این کلاس فقط یه پوسته‌ی نازکه تا home_screen.dart دست‌نخورده بمونه.
class MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Game3DTile(title: title, icon: icon, onTap: onTap);
  }
}
