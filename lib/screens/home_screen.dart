import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_card.dart';
import '../widgets/ornate_frame.dart';
import 'roster_screen.dart';
import 'stats_screen.dart';
import 'history_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'start_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                return Padding(
                  padding: EdgeInsets.fromLTRB(18, compact ? 8 : 14, 18, compact ? 12 : 16),
                  child: Column(
                    children: [
                      Expanded(
                        flex: compact ? 40 : 44,
                        child: const _HeroHeader(),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      Expanded(
                        flex: 60,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: compact ? 10 : 14,
                          crossAxisSpacing: compact ? 10 : 14,
                          childAspectRatio: compact ? 1.15 : 1.05,
                          children: [
                            MenuCard(
                              title: 'شروع بازی',
                              icon: Icons.theater_comedy,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const StartGameScreen()),
                              ),
                            ),
                            MenuCard(
                              title: 'بازیکنان',
                              icon: Icons.groups,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RosterScreen()),
                              ),
                            ),
                            MenuCard(
                              title: 'آمار',
                              icon: Icons.bar_chart,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const StatsScreen()),
                              ),
                            ),
                            MenuCard(
                              title: 'تاریخچه بازی‌ها',
                              icon: Icons.access_time,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const HistoryScreen()),
                              ),
                            ),
                            MenuCard(
                              title: 'قوانین',
                              icon: Icons.balance,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RulesScreen()),
                              ),
                            ),
                            MenuCard(
                              title: 'تنظیمات',
                              icon: Icons.settings,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned.fill(child: OrnateCornerOverlay()),
        ],
      ),
    );
  }
}

/// پس‌زمینه‌ی سینمایی: یه گرادیانِ طلایی/تیره + وینیتِ رادیال، بدونِ
/// هیچ عکس یا کاراکترِ واقعی/کپی‌رایتی خاصی.
///
/// اگه بعداً خواستی یه تصویرِ پس‌زمینه‌ی خودت (که حقِ استفاده ازش رو
/// داری) اضافه کنی، کافیه یه `Image.asset('assets/xxx.jpg', fit:
/// BoxFit.cover)` رو به‌عنوانِ اولین فرزندِ Stackِ زیر اضافه کنی و
/// مسیرش رو تو pubspec.yaml زیرِ `assets:` ثبت کنی.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.background),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.5),
              radius: 1.1,
              colors: [
                AppColors.goldDark.withOpacity(.22),
                Colors.transparent,
              ],
              stops: const [0, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.18),
              radius: .88,
              colors: [Colors.transparent, Colors.black.withOpacity(.56)],
              stops: const [.40, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.goldDark.withOpacity(.35),
                Colors.transparent,
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.theater_comedy, size: 78, color: AppColors.gold),
          ),
        ),
        const SizedBox(height: 14),
        Text('سرکوب', style: AppTheme.headingFont(size: 38)),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 54, height: 1, color: AppColors.gold.withOpacity(.55)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.diamond_outlined, color: AppColors.gold, size: 16),
            ),
            Container(width: 54, height: 1, color: AppColors.gold.withOpacity(.55)),
          ],
        ),
      ],
    );
  }
}
