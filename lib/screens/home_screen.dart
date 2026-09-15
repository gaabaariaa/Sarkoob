import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_card.dart';
import '../widgets/ornate_frame.dart';
import '../widgets/app_brand.dart';
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
      body: AppBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              children: [
                OrnateFrame(
                  borderRadius: 10,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF241E14), Color(0xFF120F0B)],
                      ),
                    ),
                    child: const BrandHeader(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(width: 4, height: 22, decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(4),
                    )),
                    const SizedBox(width: 9),
                    Text(
                      'مرکز گرداننده',
                      style: AppTheme.headingFont(size: 21),
                    ),
                    const Spacer(),
                    Text(
                      '۶ ابزار اصلی',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    physics: const BouncingScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                    children: [
                      MenuCard(
                        title: 'شروع بازی',
                        icon: Icons.play_arrow_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StartGameScreen()),
                        ),
                      ),
                      MenuCard(
                        title: 'بازیکنان',
                        icon: Icons.groups_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RosterScreen()),
                        ),
                      ),
                      MenuCard(
                        title: 'آمار',
                        icon: Icons.bar_chart_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        ),
                      ),
                      MenuCard(
                        title: 'تاریخچه بازی‌ها',
                        icon: Icons.history_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        ),
                      ),
                      MenuCard(
                        title: 'قوانین',
                        icon: Icons.menu_book_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RulesScreen()),
                        ),
                      ),
                      MenuCard(
                        title: 'تنظیمات',
                        icon: Icons.settings_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'دست خدا  •  سناریوی سرکوب',
                  style: TextStyle(
                    color: AppColors.goldLight.withOpacity(0.48),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
