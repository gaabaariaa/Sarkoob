import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'roster_screen.dart';
import 'stats_screen.dart';
import 'history_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'start_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 650;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 40 : 18,
                    18,
                    wide ? 40 : 18,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _TopBar(),
                          const SizedBox(height: 18),
                          const _HeroPanel(),
                          const SizedBox(height: 20),
                          _StartButton(
                            onTap: () => _open(context, const StartGameScreen()),
                          ),
                          const SizedBox(height: 22),
                          const _SectionTitle(title: 'مدیریت بازی'),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: wide ? 3 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: wide ? 1.55 : 1.28,
                            children: [
                              _HomeTile(
                                title: 'بازیکنان',
                                subtitle: 'لیست و نقش‌ها',
                                icon: Icons.groups_rounded,
                                onTap: () => _open(context, const RosterScreen()),
                              ),
                              _HomeTile(
                                title: 'آمار',
                                subtitle: 'نتایج و عملکرد',
                                icon: Icons.insights_rounded,
                                onTap: () => _open(context, const StatsScreen()),
                              ),
                              _HomeTile(
                                title: 'تاریخچه',
                                subtitle: 'بازی‌های قبلی',
                                icon: Icons.history_rounded,
                                onTap: () => _open(context, const HistoryScreen()),
                              ),
                              _HomeTile(
                                title: 'قوانین',
                                subtitle: 'راهنمای سناریو',
                                icon: Icons.menu_book_rounded,
                                onTap: () => _open(context, const RulesScreen()),
                              ),
                              _HomeTile(
                                title: 'تنظیمات',
                                subtitle: 'صدا و ظاهر',
                                icon: Icons.tune_rounded,
                                onTap: () => _open(context, const SettingsScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _ScenarioFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.85),
            radius: 1.15,
            colors: [
              AppColors.gold.withOpacity(0.11),
              AppColors.background,
            ],
            stops: const [0, 0.72],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _GlowOrb(size: 220, opacity: 0.045),
            ),
            Positioned(
              bottom: 40,
              left: -100,
              child: _GlowOrb(size: 260, opacity: 0.025),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold.withOpacity(opacity),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.gold.withOpacity(0.28)),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('دست خدا', style: AppTheme.headingFont(size: 25)),
              Text(
                'دستیار گرداننده بازی نقش مخفی',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'آماده',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceDark,
          ],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldLight, AppColors.gold],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.18),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.theater_comedy_rounded,
              color: Color(0xFF251A04),
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text('میز بازی', style: AppTheme.headingFont(size: 31)),
          const SizedBox(height: 4),
          Text(
            'همه‌چیز برای اجرای یک شب پرتنش آماده است.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.7,
                ),
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroTag(icon: Icons.shield_outlined, text: 'نقش مخفی'),
              const SizedBox(width: 8),
              _HeroTag(icon: Icons.nights_stay_outlined, text: 'سناریوی سرکوب'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.goldLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Game3DSurface(
      onPressed: onTap,
      palette: Game3DPalette.gold,
      depth: 6,
      borderRadius: BorderRadius.circular(19),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      semanticLabel: 'شروع بازی',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 31, color: Color(0xFF2A1B02)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شروع بازی',
                  style: AppTheme.headingFont(size: 23, color: const Color(0xFF2A1B02)),
                ),
                Text(
                  'بازیکنان را انتخاب کن و وارد سناریو شو',
                  style: TextStyle(
                    color: const Color(0xFF2A1B02).withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A1B02)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.gold.withOpacity(0.13))),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Game3DSurface(
      onPressed: onTap,
      palette: Game3DPalette.dark,
      depth: 4,
      borderRadius: BorderRadius.circular(17),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      semanticLabel: title,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.09),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.gold.withOpacity(0.16)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: AppColors.goldDark, size: 20),
        ],
      ),
    );
  }
}

class _ScenarioFooter extends StatelessWidget {
  const _ScenarioFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'دست خدا  •  سناریوی سرکوب',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
