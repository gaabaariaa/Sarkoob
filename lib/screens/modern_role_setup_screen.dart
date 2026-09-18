import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'start_game_screen.dart';

/// Entry bridge for the modern role-setup presentation.
///
/// The canonical configuration state lives in [StartGameScreen]. This screen
/// intentionally does not duplicate player/role state, so every scenario keeps
/// one source of truth for its setup logic.
class ModernRoleSetupScreen extends StatelessWidget {
  final List<String> players;
  final GameScenario scenario;

  const ModernRoleSetupScreen({
    super.key,
    this.players = const [],
    required this.scenario,
  });

  void _openCanonicalSetup(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StartGameScreen(initialScenario: scenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = SarkoobTeams.forScenario(scenario.id);
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      body: Stack(
        children: [
          _Ambient(color: scenario.color),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 18, wide ? 36 : 18, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          color: AppColors.goldLight,
                          tooltip: 'بازگشت',
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تنظیم نقش‌ها', style: AppTheme.headingFont(size: 26)),
                              const SizedBox(height: 3),
                              const Text('نمایش سناریو و ورود به تنظیمات اصلی بازی', style: TextStyle(color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        _Badge(text: '\$' + '{players.length} بازیکن'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [AppColors.surfaceElevated, AppColors.surfaceDark],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: scenario.color.withOpacity(.28)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(.30), blurRadius: 26, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(scenario.emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(scenario.name, style: AppTheme.headingFont(size: 22))),
                              _Badge(text: 'سناریوی انتخاب‌شده'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(scenario.description, style: const TextStyle(color: AppColors.mutedText, height: 1.5)),
                          if (teams.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text('تیم‌های این سناریو', style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            ...teams.map((team) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TeamCard(team: team),
                            )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: scenario.color.withOpacity(.14)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.account_tree_rounded, color: AppColors.gold),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'بازیکنان، نقش‌های قابل‌انتخاب، شمارنده‌ها و قوانین تخصیص در یک صفحهٔ اصلی مدیریت می‌شوند؛ این مسیر منطق سناریو را دوباره‌نویسی نمی‌کند.',
                            style: TextStyle(color: Colors.white70, height: 1.45),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Game3DButton(
                      label: 'ورود به تنظیمات اصلی بازی',
                      icon: Icons.tune_rounded,
                      onPressed: () => _openCanonicalSetup(context),
                    ),
                  ],
                ),
              ),
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
    child: Text(text, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800, fontSize: 11)),
  );
}

class _TeamCard extends StatelessWidget {
  final GameTeam team;
  const _TeamCard({required this.team});
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
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(.16), shape: BoxShape.circle), child: Icon(Icons.groups_rounded, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Text(team.name, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16))),
        Icon(Icons.chevron_left_rounded, color: color.withOpacity(.75)),
      ]),
    );
  }
}

class _Ambient extends StatelessWidget {
  final Color color;
  const _Ambient({required this.color});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: const Alignment(0, -.9),
          radius: 1.2,
          colors: [color.withOpacity(.09), AppColors.background],
          stops: const [0, .72],
        ),
      ),
    ),
  );
}