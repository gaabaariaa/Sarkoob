import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import '../widgets/role_info_card.dart';
import 'modern_game_flow_screen.dart';

GameTeam _teamOf(SessionPlayer p) {
  for (final t in SarkoobTeams.all) { if (t.id == p.teamId) return t; }
  return SarkoobTeams.citizen;
}

class RoleRevealScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;
  const RoleRevealScreen({super.key, required this.players, required this.settings});
  @override State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  final Set<int> _seenIds = {};
  Future<void> _openPlayer(SessionPlayer player) async {
    final confirmed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _PlayerRevealScreen(player: player, team: _teamOf(player))));
    if (confirmed == true && mounted) setState(() => _seenIds.add(player.id));
  }
  void _startGame() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ModernGameFlowScreen(players: widget.players, settings: widget.settings)));
  }
  @override Widget build(BuildContext context) {
    final allSeen = _seenIds.length == widget.players.length;
    return Scaffold(
      appBar: AppBar(title: const Text('نمایش نقش‌ها'), actions: [Padding(padding: const EdgeInsetsDirectional.only(end: 14), child: Center(child: Text(_seenIds.length.toString() + '/' + widget.players.length.toString(), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800))))]),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 4 : constraints.maxWidth >= 650 ? 3 : 2;
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(children: [
          _RevealHeader(seen: _seenIds.length, total: widget.players.length),
          const SizedBox(height: 14),
          Expanded(child: GridView.builder(itemCount: widget.players.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: columns == 2 ? 1.08 : 1.12), itemBuilder: (context, index) { final player = widget.players[index]; final seen = _seenIds.contains(player.id); return _PlayerRevealTile(name: player.name, seen: seen, onTap: seen ? null : () => _openPlayer(player)); })),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: Game3DButton(label: allSeen ? 'همه نقش‌ها دیده شد • شروع بازی' : 'بعد از دیدن همه نقش‌ها شروع کن', icon: Icons.play_arrow_rounded, onPressed: allSeen ? _startGame : null)),
        ]))));
      })),
    );
  }
}

class _RevealHeader extends StatelessWidget {
  final int seen; final int total;
  const _RevealHeader({required this.seen, required this.total});
  @override Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (seen / total).clamp(0.0, 1.0);
    return Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.gold.withOpacity(.18)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(children: [
      Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.goldDark.withOpacity(.18), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.visibility_rounded, color: AppColors.goldLight)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('نمایش خصوصی نقش', style: AppTheme.headingFont(size: 18)), const SizedBox(height: 3), const Text('هر بازیکن فقط نقش خودش را ببیند؛ سپس گوشی را به نفر بعدی بده.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.45))])), Text(seen.toString() + ' / ' + total.toString(), style: AppTheme.headingFont(size: 18, color: AppColors.goldLight))]),
      const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(minHeight: 7, value: progress, backgroundColor: Colors.white.withOpacity(.06), valueColor: const AlwaysStoppedAnimation(AppColors.gold))),
    ]));
  }
}

class _PlayerRevealTile extends StatelessWidget {
  final String name; final bool seen; final VoidCallback? onTap;
  const _PlayerRevealTile({required this.name, required this.seen, required this.onTap});
  @override Widget build(BuildContext context) {
    final c = seen ? Game3DColors.disabled : Game3DColors.of(Game3DPalette.gold);
    return Game3DSurface(onPressed: onTap, palette: Game3DPalette.gold, depth: 6, borderRadius: BorderRadius.circular(18), semanticLabel: name, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(.18), border: Border.all(color: c.text.withOpacity(.7), width: 1.4)), child: Icon(seen ? Icons.check_circle : Icons.person, color: c.text, size: 24)), const SizedBox(height: 8), Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w800))])));
  }
}

class _PlayerRevealScreen extends StatefulWidget {
  final SessionPlayer player; final GameTeam team;
  const _PlayerRevealScreen({required this.player, required this.team});
  @override State<_PlayerRevealScreen> createState() => _PlayerRevealScreenState();
}
class _PlayerRevealScreenState extends State<_PlayerRevealScreen> {
  bool _revealed = true;
  @override Widget build(BuildContext context) {
    final player = widget.player; final team = widget.team; final role = player.roleId != null ? SarkoobRoles.byId(player.roleId!) : null;
    return Scaffold(appBar: AppBar(title: const Text('نمایش نقش')), body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.gold.withOpacity(.14))), child: Column(children: [const Text('گوشی دستِ:', style: TextStyle(color: AppColors.mutedText, fontSize: 12)), const SizedBox(height: 3), Text(player.name, style: AppTheme.headingFont(size: 26), textAlign: TextAlign.center)])),
      const SizedBox(height: 14), Expanded(child: Center(child: SingleChildScrollView(child: role != null ? RoleInfoCard(role: role, team: team) : _GenericTeamCard(team: team)))),
      const SizedBox(height: 12), SizedBox(width: double.infinity, child: Game3DButton(label: 'دیدم، برگرد', icon: Icons.check_rounded, onPressed: () => Navigator.of(context).pop(true))),
    ]))));
  }
}

class _HiddenCard extends StatelessWidget {
  const _HiddenCard();
  @override Widget build(BuildContext context) => Container(width: 280, height: 360, decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gold.withOpacity(.55), width: 1.4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.28), blurRadius: 24, offset: const Offset(0, 12))]), alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.goldDark.withOpacity(.18), border: Border.all(color: AppColors.gold.withOpacity(.3))), child: const Icon(Icons.lock_outline_rounded, size: 38, color: AppColors.goldLight)), const SizedBox(height: 16), Text('نقش مخفی است', style: AppTheme.headingFont(size: 20)), const SizedBox(height: 6), const Text('برای نمایش، کارت را لمس کن', style: TextStyle(color: AppColors.mutedText))]));
}

class _GenericTeamCard extends StatelessWidget {
  final GameTeam team; const _GenericTeamCard({required this.team});
  @override Widget build(BuildContext context) => Container(width: 300, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: team.color, width: 1.7), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shield_rounded, size: 52, color: team.color), const SizedBox(height: 12), Text(team.name, textAlign: TextAlign.center, style: TextStyle(color: team.color, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(team.description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, height: 1.5))]));
}