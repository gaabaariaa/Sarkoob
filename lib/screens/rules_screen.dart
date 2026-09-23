import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/role_card.dart';
import '../widgets/role_info_card.dart';

class RulesScreen extends StatefulWidget {
  RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  GameScenario _selectedScenario = GameScenarios.defaultScenario;

  @override
  Widget build(BuildContext context) {
    final teams = GameTeams.selectableForScenario(_selectedScenario.id);

    return Scaffold(
      appBar: AppBar(title: Text('قوانین و نقش‌ها'.tr.tr.tr), actions: [Padding(padding: EdgeInsetsDirectional.only(end: 14), child: Center(child: Text(_selectedScenario.name, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12))))],),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.uiPrimary.withAlpha(46))),
            child: SegmentedButton<GameScenario>(
              showSelectedIcon: false,
              segments: GameScenarios.all
                  .map(
                    (s) => ButtonSegment<GameScenario>(
                      value: s,
                      label: Text('${s.emoji} ${s.name}'),
                    ),
                  )
                  .toList(),
              selected: {_selectedScenario},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedScenario = selection.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Container(padding: EdgeInsets.all(20), margin: EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: _selectedScenario.color.withAlpha(102))), child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: _selectedScenario.color.withAlpha(46), shape: BoxShape.circle), child: Center(child: Text(_selectedScenario.emoji, style: TextStyle(fontSize: 26)))), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('راهنمای سناریو'.tr, style: AppTheme.headingFont(size: 21)), SizedBox(height: 5), Text(_selectedScenario.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11, height: 1.45))]))]),),
                Row(children: [Icon(Icons.groups_rounded, color: AppTheme.uiPrimaryLight, size: 19), SizedBox(width: 8), Text('تیم‌ها و نقش‌ها'.tr, style: AppTheme.headingFont(size: 19))]),
                SizedBox(height: 4),
                Text(
                  'نقش‌ها به‌مرور اضافه می‌شن. روی اسم تیم بزن تا کارت پیش‌نمایش '.tr
                  'تیم رو ببینی؛ روی هر نقش بزن تا کارت کاملش رو ببینی.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 6),
                Text(
                  '🏆 علاوه‌بر امتیازدهیِ اختصاصیِ هر نقش (که زیرِ خودش نوشته شده)، '.tr
                  'همه‌ی بازیکنان از رأی‌گیری (رأیِ خروج)، رأیِ رهبری، بقا، و سیستمِ '
                  'انضباطی هم امتیاز می‌گیرن — این‌ها مشترکه و زیرِ هر نقش تکرار نشده. '
                  'امتیازِ رأی/رفراندوم بر اساسِ نقش ضریب می‌خوره: شهروندِ‌خاکستری/'
                  'simpleCitizen چون هیچ اکشنِ اختصاصی ندارن x۲، سرکوبگر/simpleMafia '
                  'x۱.۵، رهبرِ موساد/زودیاک (که خودشون اکشنِ اختصاصیِ پرامتیاز دارن) '
                  'x۰.۵، بقیه x۱. فازِ آشوب (سه‌نفرِ آخر) هم امتیازِ خودشو داره: دو نفری '
                  'که با هم دست دادن اگه تیمشون برد +۳، اگه به‌اشتباه به سودِ حریف بود '
                  '-۳؛ نفرِ سومی که بیرون موند و تیمش باخت -۱.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                SizedBox(height: 16),
                ...teams.map((team) => _TeamSection(team: team)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final GameTeam team;
  _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    final roles = GameRoles.forTeam(team.id);
    return Card(
      color: AppTheme.uiCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: team.color.withAlpha(153)),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _TeamPreviewScreen(team: team)),
            ),
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: team.color.withAlpha(46), shape: BoxShape.circle, border: Border.all(color: team.color.withAlpha(115))), child: Icon(Icons.groups_rounded, color: team.color)),
            title: Text(
              team.localizedName,
              style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(team.localizedDescription, style: TextStyle(color: Colors.white60)),
            trailing: Icon(Icons.chevron_left_rounded, color: AppTheme.uiPrimary),
          ),
          if (roles.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('هنوز نقشی برای این تیم اضافه نشده.'.tr,
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            )
          else
            ...roles.map(
              (role) => ListTile(
                dense: true,
                title: Text(role.localizedName, style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.chevron_left_rounded, color: AppTheme.uiPrimary, size: 19),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _RolePreviewScreen(role: role, team: team),
                  ),
                ),
              ),
            ),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TeamPreviewScreen extends StatelessWidget {
  final GameTeam team;
  _TeamPreviewScreen({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('پیش‌نمایش کارت — ${team.localizedName}')),
      body: Center(
        child: TeamRevealCard(team: team, playerName: 'بازیکن نمونه'),
      ),
    );
  }
}

class _RolePreviewScreen extends StatelessWidget {
  final GameRole role;
  final GameTeam team;
  _RolePreviewScreen({required this.role, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(role.localizedName)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: RoleInfoCard(role: role, team: team, showScoringInfo: true),
      ),
    );
  }
}
