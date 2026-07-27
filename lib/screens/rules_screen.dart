import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/role_info_card.dart';
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
          Text('تیم‌ها و نقش‌ها', style: AppTheme.headingFont(size: 22)),
          const SizedBox(height: 4),
          const Text(
            'نقش‌ها به‌مرور اضافه می‌شن. روی اسم تیم بزن تا کارت پیش‌نمایش '
            'تیم رو ببینی؛ روی هر نقش بزن تا کارت کاملش رو ببینی.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...SarkoobTeams.all.map((team) => _TeamSection(team: team)),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final GameTeam team;
  const _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    final roles = SarkoobRoles.forTeam(team.id);
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: team.color.withOpacity(0.6)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _TeamPreviewScreen(team: team)),
            ),
            leading: CircleAvatar(backgroundColor: team.color),
            title: Text(
              team.name,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(team.description, style: const TextStyle(color: Colors.white60)),
            trailing: const Icon(Icons.chevron_left, color: AppColors.gold),
          ),
          if (roles.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('هنوز نقشی برای این تیم اضافه نشده.',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            )
          else
            ...roles.map(
              (role) => ListTile(
                dense: true,
                title: Text(role.name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.badge, color: AppColors.gold, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _RolePreviewScreen(role: role, team: team),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
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

class _RolePreviewScreen extends StatelessWidget {
  final GameRole role;
  final GameTeam team;
  const _RolePreviewScreen({required this.role, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(role.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RoleInfoCard(role: role, team: team),
      ),
    );
  }
}
