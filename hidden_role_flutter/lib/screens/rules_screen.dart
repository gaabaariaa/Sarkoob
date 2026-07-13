import 'package:flutter/material.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/role_card.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قوانین — سناریوی سرکوب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'تیم‌ها',
            style: AppTheme.headingFont(size: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'نقش‌ها به‌مرور اضافه می‌شن؛ فعلاً فقط تیم‌ها آماده‌ست. '
            'روی هر تیم بزن تا کارت پیش‌نمایشش رو ببینی.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...SarkoobTeams.all.map(
            (team) => Card(
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: team.color.withOpacity(0.6)),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TeamPreviewScreen(team: team),
                  ),
                ),
                leading: CircleAvatar(backgroundColor: team.color),
                title: Text(
                  team.name,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  team.description,
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: const Icon(Icons.chevron_left, color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPreviewScreen extends StatelessWidget {
  final GameTeam team;
  const _TeamPreviewScreen({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش‌نمایش کارت — ${team.name}')),
      body: Center(
        child: TeamRevealCard(team: team, playerName: 'بازیکن نمونه'),
      ),
    );
  }
}
