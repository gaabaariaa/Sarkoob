import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import '../widgets/role_info_card.dart';
import 'game_flow_screen.dart';

GameTeam _teamOf(SessionPlayer p) {
  for (final t in SarkoobTeams.all) {
    if (t.id == p.teamId) return t;
  }
  return SarkoobTeams.citizen;
}

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
  final Set<int> _seenIds = {};

  Future<void> _openPlayer(SessionPlayer player) async {
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _PlayerRevealScreen(player: player, team: _teamOf(player)),
      ),
    );
    if (confirmed == true && mounted) setState(() => _seenIds.add(player.id));
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameFlowScreen(players: widget.players, settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSeen = _seenIds.length == widget.players.length;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryLight = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('نمایش نقش‌ها')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.visibility_outlined, color: primaryLight, size: 25),
                    const SizedBox(height: 6),
                    Text(
                      'هر بازیکن فقط نقش خودش را ببیند',
                      textAlign: TextAlign.center,
                      style: AppTheme.headingFont(size: 18, color: primaryLight),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'روی اسم خودت بزن، نقش را ببین و بعد گوشی را به نفر بعدی بده.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  itemCount: widget.players.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final player = widget.players[index];
                    final seen = _seenIds.contains(player.id);
                    return _PlayerRevealTile(
                      name: player.name,
                      seen: seen,
                      onTap: seen ? null : () => _openPlayer(player),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'دیده‌شده: ${_seenIds.length} از ${widget.players.length}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Game3DButton(
                  label: 'شروع بازی',
                  icon: Icons.play_arrow_rounded,
                  onPressed: allSeen ? _startGame : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerRevealTile extends StatelessWidget {
  final String name;
  final bool seen;
  final VoidCallback? onTap;

  const _PlayerRevealTile({required this.name, required this.seen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = seen ? Game3DColors.disabled : Game3DColors.of(Game3DPalette.gold);
    return Game3DSurface(
      onPressed: onTap,
      palette: Game3DPalette.gold,
      depth: 6,
      borderRadius: BorderRadius.circular(18),
      semanticLabel: name,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.18),
                border: Border.all(color: c.text.withOpacity(0.7), width: 1.4),
              ),
              child: Icon(seen ? Icons.check_circle : Icons.person, color: c.text, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRevealScreen extends StatefulWidget {
  final SessionPlayer player;
  final GameTeam team;

  const _PlayerRevealScreen({required this.player, required this.team});

  @override
  State<_PlayerRevealScreen> createState() => _PlayerRevealScreenState();
}

class _PlayerRevealScreenState extends State<_PlayerRevealScreen> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final team = widget.team;
    final role = player.roleId != null ? SarkoobRoles.byId(player.roleId!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('نمایش نقش')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Text('گوشی دستِ:', style: TextStyle(color: Colors.white.withOpacity(0.58))),
              const SizedBox(height: 2),
              Text(player.name, style: AppTheme.headingFont(size: 28)),
              const SizedBox(height: 14),
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
              SizedBox(
                width: double.infinity,
                child: Game3DButton(
                  label: 'دیدم، برگرد',
                  icon: Icons.check_rounded,
                  onPressed: _revealed ? () => Navigator.of(context).pop(true) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiddenCard extends StatelessWidget {
  const _HiddenCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 250,
      height: 330,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.75), width: 1.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 56, color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text(
            'برای دیدن نقش لمس کن',
            style: TextStyle(color: Colors.white.withOpacity(0.72), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text('اطلاعات نقش مخفی است', style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11)),
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
    // team.color عمداً ثابت می‌ماند؛ تم فقط قاب و سطح کارت را کنترل می‌کند.
    final theme = Theme.of(context);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: team.color, width: 1.7),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 50, color: team.color),
          const SizedBox(height: 12),
          Text(
            team.name,
            style: TextStyle(color: team.color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            team.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.68)),
          ),
        ],
      ),
    );
  }
}
