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

/// هابِ نمایشِ نقش‌ها: به‌جایِ ترتیبِ ثابت، اسمِ همه‌ی بازیکن‌ها به‌صورتِ
/// دکمه نشون داده می‌شه؛ هرکس با زدنِ روی اسمِ خودش نقش (یا تیمش) رو
/// می‌بینه، به هر ترتیبی که خواست. دکمه‌ی «شروعِ بازی» فقط وقتی فعال
/// می‌شه که همه دیده باشن.
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
    if (confirmed == true && mounted) {
      setState(() => _seenIds.add(player.id));
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('نمایش نقش‌ها')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'گوشی رو بچرخونین؛ هر بازیکن روی اسمِ خودش بزنه تا نقشش رو ببینه.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Text(
              'دیده‌شده: ${_seenIds.length} از ${widget.players.length}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Game3DButton(
              label: 'شروع بازی',
              icon: Icons.play_arrow,
              onPressed: allSeen ? _startGame : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// کاشیِ اسمِ یه بازیکن تو گریدِ هاب. مثلِ `Game3DTile` ولی برخلافِ اون،
/// `onTap` می‌تونه null باشه (بازیکنی که قبلاً نقشش رو دیده) تا خودکار
/// به‌شکلِ غیرفعال/طوسی دربیاد و دیگه قابلِ‌لمس نباشه.
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

/// صفحه‌ی نمایشِ نقشِ یه بازیکنِ تک: کارتِ مخفی، لمس برای دیدن، و دکمه‌ی
/// تأیید که فقط بعدِ دیدنِ نقش فعال می‌شه و با `pop(true)` به هاب خبر
/// می‌ده این بازیکن دیده. برگشتنِ بدونِ تأیید (دکمه‌ی بازِ اپ‌بار یا
/// بک‌ِ گوشی) چیزی رو «دیده‌شده» علامت نمی‌زنه.
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
      appBar: AppBar(title: const Text('نمایشِ نقش')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('گوشی دستِ:', style: TextStyle(color: Colors.white70)),
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
            Game3DButton(
              label: 'دیدم، برگرد',
              icon: Icons.check,
              onPressed: _revealed ? () => Navigator.of(context).pop(true) : null,
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
