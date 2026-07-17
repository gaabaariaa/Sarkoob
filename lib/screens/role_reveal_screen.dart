import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/role_info_card.dart';
import 'game_flow_screen.dart';

/// گوشی دست‌به‌دست می‌شه: هر بازیکن روی کارتش لمس می‌کنه تا نقش (اگه نقشِ
/// خاصی داشته باشه) یا تیمش (در غیر این صورت) رو ببینه.
class RoleRevealScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;

  const RoleRevealScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  int _index = 0;
  bool _revealed = false;

  GameTeam _teamOf(SessionPlayer p) {
    for (final t in SarkoobTeams.all) {
      if (t.id == p.teamId) return t;
    }
    return SarkoobTeams.citizen;
  }

  void _next() {
    if (_index < widget.players.length - 1) {
      setState(() {
        _index++;
        _revealed = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameFlowScreen(players: widget.players, settings: widget.settings),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.players[_index];
    final team = _teamOf(player);
    final role = player.roleId != null ? SarkoobRoles.byId(player.roleId!) : null;
    final isLast = _index == widget.players.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('نمایش نقش‌ها')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('گوشی رو بده به:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(player.name, style: AppTheme.headingFont(size: 28)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _revealed = !_revealed),
                  child: _revealed
                      ? SingleChildScrollView(
                          child: role != null
                              ? RoleInfoCard(role: role, team: team)
                              : _GenericTeamCard(team: team),
                        )
                      : const _HiddenCard(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _revealed ? _next : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(isLast ? 'شروع بازی' : 'نفر بعدی'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenCard extends StatelessWidget {
  const _HiddenCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 56, color: AppColors.gold),
          SizedBox(height: 12),
          Text('برای دیدن نقش لمس کن', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _GenericTeamCard extends StatelessWidget {
  final GameTeam team;
  const _GenericTeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: team.color, width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, size: 48, color: team.color),
          const SizedBox(height: 12),
          Text(
            team.name,
            style: TextStyle(color: team.color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            team.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
