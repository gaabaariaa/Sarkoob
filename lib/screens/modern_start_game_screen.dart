import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'start_game_screen.dart';

class ModernStartGameScreen extends StatefulWidget {
  const ModernStartGameScreen({super.key});

  @override
  State<ModernStartGameScreen> createState() => _ModernStartGameScreenState();
}

class _ModernStartGameScreenState extends State<ModernStartGameScreen> {
  GameScenario _scenario = SarkoobScenarios.mafia;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StartGameScreen(initialScenario: _scenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _Ambient(color: _scenario.color),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.goldDark.withOpacity(.18),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.gold.withOpacity(.22)),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('شروع بازی', style: AppTheme.headingFont(size: 28)),
                              const SizedBox(height: 3),
                              const Text('میز بازی را برای سناریوی انتخابی آماده کن.', style: TextStyle(color: AppColors.mutedText)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.gold.withOpacity(.18)),
                          ),
                          child: const Text('دست خدا', style: TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'سناریوی بازی',
                      child: DropdownButtonFormField<GameScenario>(
                        value: _scenario,
                        dropdownColor: AppColors.surfaceCard,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.auto_awesome_rounded), border: OutlineInputBorder()),
                        items: SarkoobScenarios.all.map((scenario) => DropdownMenuItem(value: scenario, child: Text('${scenario.emoji}  ${scenario.name}'))).toList(),
                        onChanged: (value) { if (value != null) setState(() => _scenario = value); },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'مرحله بعد',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تنظیمات ' + _scenario.name, style: AppTheme.headingFont(size: 19)),
                          const SizedBox(height: 8),
                          const Text('بازیکن‌ها، تیم‌ها، نقش‌ها، زمان صحبت و تنظیمات بازی در صفحهٔ اصلی تنظیمات مدیریت می‌شوند تا منطق هیچ سناریویی بین دو مسیر UI دو نسخه نشود.', style: TextStyle(color: AppColors.mutedText, height: 1.55)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Game3DButton(label: 'ورود به تنظیمات ' + _scenario.name, icon: Icons.arrow_forward_rounded, onPressed: _continue),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.gold.withOpacity(.16))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.headingFont(size: 18)), const SizedBox(height: 12), child]),
  );
}

class _Ambient extends StatelessWidget {
  final Color color;
  const _Ambient({required this.color});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background, gradient: RadialGradient(center: const Alignment(0, -.8), radius: 1.2, colors: [color.withOpacity(.09), AppColors.background], stops: const [0, .72])),
    ),
  );
}