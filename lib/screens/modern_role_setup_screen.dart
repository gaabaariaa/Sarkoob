import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/team.dart';
import '../widgets/game_3d_button.dart';
import 'start_game_screen.dart';

/// هاب بصری تنظیم نقش‌ها؛ منطق واقعی نقش‌بندی همچنان در StartGameScreen است.
/// رنگ تیم‌ها مستقیماً از مدل تیم خوانده می‌شود و دستکاری نمی‌شود.
class ModernRoleSetupScreen extends StatelessWidget {
  final List<String> players;

  const ModernRoleSetupScreen({super.key, this.players = const []});

  @override
  Widget build(BuildContext context) {
    final count = players.length;
    return Scaffold(
      body: Stack(
        children: [
          const _Ambient(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 18, wide ? 36 : 18, 28),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تنظیم نقش‌ها', style: AppTheme.headingFont(size: 26)),
                                  Text('ترکیب میز و تیم‌ها را آماده کن', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
                                ],
                              ),
                            ),
                            _Badge(text: '$count بازیکن'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [AppColors.surfaceElevated, AppColors.surfaceDark],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.gold.withOpacity(.20)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.30), blurRadius: 26, offset: const Offset(0, 12))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('سناریوی سرکوب', style: AppTheme.headingFont(size: 22)),
                              const SizedBox(height: 5),
                              Text('ابتدا تیم‌ها را مرور کن؛ انتخاب دقیق تعداد نقش‌ها در تنظیمات کامل انجام می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
                              const SizedBox(height: 18),
                              _TeamCard(team: SarkoobTeams.suppression, icon: Icons.shield_rounded, subtitle: 'نقش‌های تیم سرکوب و سرکوبگرهای ساده'),
                              const SizedBox(height: 10),
                              _TeamCard(team: SarkoobTeams.citizen, icon: Icons.groups_rounded, subtitle: 'نقش‌های شهروندی و شهروند خاکستری'),
                              const SizedBox(height: 10),
                              _TeamCard(team: SarkoobTeams.mossad, icon: Icons.visibility_rounded, subtitle: 'تیم مستقل — در صورت فعال‌سازی'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.gold.withOpacity(.12)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight),
                              SizedBox(width: 10),
                              Expanded(child: Text('تخصیص نقش به بازیکنان همچنان تصادفی و طبق منطق فعلی بازی انجام می‌شود.', style: TextStyle(color: Colors.white70, height: 1.45))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Game3DButton(
                          label: 'باز کردن تنظیمات کامل نقش‌ها',
                          icon: Icons.tune_rounded,
                          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StartGameScreen())),
                        ),
                      ],
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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.gold.withOpacity(.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold.withOpacity(.18)),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800)),
  );
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final IconData icon;
  final String subtitle;
  const _TeamCard({required this.team, required this.icon, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final color = team.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Row(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(.16), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(team.name, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
          Icon(Icons.chevron_left_rounded, color: color.withOpacity(.75)),
        ],
      ),
    );
  }
}

class _Ambient extends StatelessWidget {
  const _Ambient();
  @override
  Widget build(BuildContext context) => Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: AppColors.background, gradient: RadialGradient(center: const Alignment(0, -.9), radius: 1.2, colors: [AppColors.gold.withOpacity(.09), AppColors.background], stops: const [0, .72]))));
}
