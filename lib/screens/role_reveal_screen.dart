import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/game_3d_button.dart';
import '../widgets/role_info_card.dart';
import 'modern_game_flow_screen.dart';

GameTeam _teamOf(SessionPlayer p) {
  for (final t in GameTeams.all) {
    if (t.id == p.teamId) return t;
  }
  throw StateError('Unknown team "${p.teamId}" for player ${p.id}');
}

class RoleRevealScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;
  RoleRevealScreen({super.key, required this.players, required this.settings});
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
      appBar: AppBar(title: Text('نمایش نقش‌ها'.tr.tr.tr), actions: [Padding(padding: EdgeInsetsDirectional.only(end: 14), child: Center(child: Text(_seenIds.length.toString() + '/' + widget.players.length.toString(), style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800))))]),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final columns = constraints.maxWidth >= 1000 ? 4 : constraints.maxWidth >= 650 ? 3 : 2;
        return Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1100), child: Padding(padding: EdgeInsets.fromLTRB(compact ? 10 : 16, compact ? 6 : 8, compact ? 10 : 16, compact ? 12 : 16), child: Column(children: [
          _RevealHeader(seen: _seenIds.length, total: widget.players.length),
          SizedBox(height: 14),
          Expanded(child: GridView.builder(itemCount: widget.players.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: compact ? 8 : 12, crossAxisSpacing: compact ? 8 : 12, childAspectRatio: columns == 2 ? (compact ? .92 : 1.08) : 1.12), itemBuilder: (context, index) { final player = widget.players[index]; final seen = _seenIds.contains(player.id); return _PlayerRevealTile(name: player.name, seen: seen, onTap: seen ? null : () => _openPlayer(player)); })),
          SizedBox(height: 10),
          SizedBox(width: double.infinity, child: Game3DButton(label: allSeen ? 'همه نقش‌ها دیده شد • شروع بازی' : 'بعد از دیدن همه نقش‌ها شروع کن', icon: Icons.play_arrow_rounded, onPressed: allSeen ? _startGame : null)),
        ]))));
      })),
    );
  }
}

class _RevealHeader extends StatelessWidget {
  final int seen; final int total;
  _RevealHeader({required this.seen, required this.total});
  @override Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (seen / total).clamp(0.0, 1.0);
    return Container(width: double.infinity, padding: EdgeInsets.all(18), decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.uiPrimary.withAlpha(46)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(56), blurRadius: 20, offset: Offset(0, 10))]), child: Column(children: [
      Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(46), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.visibility_rounded, color: AppTheme.uiPrimaryLight)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('نمایش خصوصی نقش'.tr, style: AppTheme.headingFont(size: 18)), SizedBox(height: 3), Text('هر بازیکن فقط نقش خودش را ببیند؛ سپس گوشی را به نفر بعدی بده.'.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.45))])), Text(seen.toString() + ' / ' + total.toString(), style: AppTheme.headingFont(size: 18, color: AppTheme.uiPrimaryLight))]),
      SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(minHeight: 7, value: progress, backgroundColor: Colors.white.withAlpha(15), valueColor: AlwaysStoppedAnimation(AppTheme.uiPrimary))),
    ]));
  }
}

class _PlayerRevealTile extends StatelessWidget {
  final String name; final bool seen; final VoidCallback? onTap;
  _PlayerRevealTile({required this.name, required this.seen, required this.onTap});
  @override Widget build(BuildContext context) {
    final c = seen ? Game3DColors.disabled : Game3DColors.of(Game3DPalette.gold);
    return Game3DSurface(onPressed: onTap, palette: Game3DPalette.gold, depth: 6, borderRadius: BorderRadius.circular(18), semanticLabel: name, padding: EdgeInsets.symmetric(vertical: 13, horizontal: 8), child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withAlpha(46), border: Border.all(color: c.text.withAlpha(179), width: 1.4)), child: Icon(seen ? Icons.check_circle : Icons.person, color: c.text, size: 24)), SizedBox(height: 8), Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w800))])));
  }
}

class _PlayerRevealScreen extends StatefulWidget {
  final SessionPlayer player; final GameTeam team;
  _PlayerRevealScreen({required this.player, required this.team});
  @override State<_PlayerRevealScreen> createState() => _PlayerRevealScreenState();
}
class _PlayerRevealScreenState extends State<_PlayerRevealScreen> {
  @override Widget build(BuildContext context) {
    final player = widget.player; final team = widget.team; final role = player.roleId != null ? GameRoles.byId(player.roleId!) : null;
    return Scaffold(appBar: AppBar(title: Text('نمایش نقش'.tr.tr)), body: SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 16), child: Column(children: [
      Container(width: double.infinity, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.uiPrimary.withAlpha(36))), child: Column(children: [Text('گوشی دستِ:'.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)), SizedBox(height: 3), Text(player.name, style: AppTheme.headingFont(size: 26), textAlign: TextAlign.center)])),
      SizedBox(height: 14), Expanded(child: Center(child: SingleChildScrollView(child: role != null ? RoleInfoCard(role: role, team: team) : _GenericTeamCard(team: team)))),
      SizedBox(height: 12), SizedBox(width: double.infinity, child: Game3DButton(label: 'دیدم، برگرد', icon: Icons.check_rounded, onPressed: () => Navigator.of(context).pop(true))),
    ]))));
  }
}

class _GenericTeamCard extends StatelessWidget {
  final GameTeam team; _GenericTeamCard({required this.team});
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final compact = constraints.maxWidth < 360;
    return Container(
      width: constraints.maxWidth.clamp(0, 340),
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: team.color, width: 1.7), boxShadow: [BoxShadow(color: Colors.black.withAlpha(64), blurRadius: 20, offset: Offset(0, 10))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_rounded, size: compact ? 44 : 52, color: team.color),
        SizedBox(height: compact ? 9 : 12),
        Text(team.name, textAlign: TextAlign.center, style: TextStyle(color: team.color, fontSize: compact ? 21 : 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(team.description, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.uiMutedText, height: 1.5)),
      ]),
    );
  });
}