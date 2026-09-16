import 'package:flutter/material.dart';
import 'roster_screen.dart';
import 'stats_screen.dart';
import 'history_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'start_game_screen.dart';

/// صفحه‌ی اصلی بر اساس طرح مرجع دست خدا.
/// تصویر لایه‌ی بصری دقیق طرح است و نواحی نامرئی روی کارت‌ها ناوبری واقعی اپ را اجرا می‌کنند.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              final fittedWidth = maxWidth <= maxHeight * 864 / 1536
                  ? maxWidth
                  : maxHeight * 864 / 1536;
              final fittedHeight = fittedWidth * 1536 / 864;

              return SizedBox(
                width: fittedWidth,
                height: fittedHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/home_reference.webp',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                    _HitTarget(
                      left: .095, top: .410, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'شروع بازی',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StartGameScreen()),
                      ),
                    ),
                    _HitTarget(
                      left: .512, top: .410, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'بازیکنان',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RosterScreen()),
                      ),
                    ),
                    _HitTarget(
                      left: .095, top: .595, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'آمار',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                    _HitTarget(
                      left: .512, top: .595, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'تاریخچه بازی ها',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
                    _HitTarget(
                      left: .095, top: .780, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'قوانین',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RulesScreen()),
                      ),
                    ),
                    _HitTarget(
                      left: .512, top: .780, width: .385, height: .168,
                      canvasWidth: fittedWidth, canvasHeight: fittedHeight,
                      label: 'تنظیمات',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HitTarget extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final double canvasWidth;
  final double canvasHeight;
  final String label;
  final VoidCallback onTap;

  const _HitTarget({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: canvasWidth * left,
      top: canvasHeight * top,
      width: canvasWidth * width,
      height: canvasHeight * height,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
