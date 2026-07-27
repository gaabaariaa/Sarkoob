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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              OrnateFrame(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF241E14), AppColors.background],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.theater_comedy,
                        size: 80,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 14),
                      Text('سرکوب', style: AppTheme.headingFont(size: 36)),
                      const SizedBox(height: 12),
                      const OrnateDivider(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
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
        ),
      ),
    );
  }
}
