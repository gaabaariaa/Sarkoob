import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/role_card.dart';
import '../widgets/role_info_card.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  GameScenario _selectedScenario = SarkoobScenarios.defaultScenario;

  @override
  Widget build(BuildContext context) {
    final teams = SarkoobTeams.selectableForScenario(_selectedScenario.id);

    return Scaffold(
      appBar: AppBar(title: const Text('قوانین و نقش‌ها'), actions: [Padding(padding: const EdgeInsetsDirectional.only(end: 14), child: Center(child: Text(_selectedScenario.name, style: const TextStyle(color: AppColors.mutedText, fontSize: 12))))],),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.gold.withAlpha(46))),
            child: SegmentedButton<GameScenario>(
              showSelectedIcon: false,
              segments: SarkoobScenarios.all
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
              padding: const EdgeInsets.all(16),
              children: [
                Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: _selectedScenario.color.withAlpha(102))), child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: _selectedScenario.color.withAlpha(46), shape: BoxShape.circle), child: Center(child: Text(_selectedScenario.emoji, style: const TextStyle(fontSize: 26)))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('راهنمای سناریو', style: AppTheme.headingFont(size: 21)), const SizedBox(height: 5), Text(_selectedScenario.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.45))]))]),),
                Row(children: [const Icon(Icons.groups_rounded, color: AppColors.goldLight, size: 19), const SizedBox(width: 8), Text('تیم‌ها و نقش‌ها', style: AppTheme.headingFont(size: 19))]),
                const SizedBox(height: 4),
                const Text(
                  'نقش‌ها به‌مرور اضافه می‌شن. روی اسم تیم بزن تا کارت پیش‌نمایش '
                  'تیم رو ببینی؛ روی هر نقش بزن تا کارت کاملش رو ببینی.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                const Text(
                  '🏆 علاوه‌بر امتیازدهیِ اختصاصیِ هر نقش (که زیرِ خودش نوشته شده)، '
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
                const SizedBox(height: 16),
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
  const _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    final roles = SarkoobRoles.forTeam(team.id);
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: team.color.withAlpha(153)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _TeamPreviewScreen(team: team)),
            ),
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: team.color.withAlpha(46), shape: BoxShape.circle, border: Border.all(color: team.color.withAlpha(115))), child: Icon(Icons.groups_rounded, color: team.color)),
            title: Text(
              team.name,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(team.description, style: const TextStyle(color: Colors.white60)),
            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.gold),
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
                trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.gold, size: 19),
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
        child: RoleInfoCard(role: role, team: team, showScoringInfo: true),
      ),
    );
  }
}
