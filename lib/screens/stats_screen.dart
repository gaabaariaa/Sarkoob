import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/role_success_metric.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../utils/jalali_date.dart';

class StatsScreen extends StatefulWidget {
  StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _PlayerAggregate {
  final String key;
  String displayName;
  int games = 0;
  int wins = 0;
  int disciplineScore = 0; // مجموعِ disciplineStage (۰-۴) تو همه‌ی بازی‌ها — برای «بی‌انضباط‌ترین»
  int totalScoreSum = 0; // مجموعِ خامِ همه‌ی totalScoreهای این بازیکن — فقط برایِ محاسبه‌ی میانگین
  int challengesGivenTotal = 0; // مجموعِ کلِ همه‌ی بازی‌ها — برای «چالش‌بده‌ترین»
  int challengesReceivedTotal = 0; // مجموعِ کلِ همه‌ی بازی‌ها — برای «چالش‌بگیرترین»
  int totalSpeakingSeconds = 0; // مجموعِ واقعیِ ثانیه‌های صحبت/چالش در همه‌ی بازی‌ها
  final List<_PlayerGameRow> rows = [];

  _PlayerAggregate({required this.key, required this.displayName});

  /// میانگینِ امتیازِ این بازیکن به‌ازایِ هر بازی (سندِ طراحیِ امتیازدهی:
  /// آمارِ درازمدت باید میانگین باشه، نه مجموعِ خام، وگرنه کسی که بیشتر
  /// بازی کرده صرفاً به‌خاطرِ تعداد جلو می‌افته).
  double get avgScore => games == 0 ? 0 : totalScoreSum / games;
}

class _PlayerGameRow {
  final DateTime playedAt;
  final String teamName;
  final String? roleName;
  final bool won;
  final int disciplineStage;
  final int score;
  _PlayerGameRow({
    required this.playedAt,
    required this.teamName,
    this.roleName,
    required this.won,
    this.disciplineStage = 0,
    this.score = 0,
  });
}

class _RoleRanking {
  final String playerName;
  final int count;
  _RoleRanking({required this.playerName, required this.count});
}

class _RoleBest {
  final String roleName;
  final String unitLabel;
  final List<_RoleRanking> rankings; // مرتب‌شده، بیشترین اول
  _RoleBest({
    required this.roleName,
    required this.unitLabel,
    required this.rankings,
  });
}

class _RoleBestRow extends StatelessWidget {
  final _RoleBest best;
  _RoleBestRow({required this.best});

  @override
  Widget build(BuildContext context) {
    final top = best.rankings.first;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(41)),
      ),
      child: ExpansionTile(
        iconColor: AppTheme.uiPrimary,
        collapsedIconColor: Colors.white38,
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(Icons.military_tech, color: AppTheme.uiPrimaryLight, size: 20),
        title: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white, fontSize: 13),
            children: [
              TextSpan(
                text: 'بهترین ${best.roleName}: ',
                style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${top.playerName} با ${top.count} ${best.unitLabel}'),
            ],
          ),
        ),
        subtitle: best.rankings.length > 1
            ? Text(
                '${best.rankings.length} بازیکن این نقش رو بازی کرده‌ن — بزن تا بقیه‌ی رتبه‌ها رو ببینی',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              )
            : null,
        children: [
          Divider(color: Colors.white24, height: 1),
          ...best.rankings.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final r = entry.value;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.playerName,
                      style: TextStyle(
                        color: rank == 1 ? AppTheme.uiPrimaryLight : Colors.white70,
                        fontSize: 13,
                        fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${r.count} ${best.unitLabel}',
                    style: TextStyle(
                      color: rank == 1 ? AppTheme.uiPrimaryLight : Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storage = StorageService();
  List<GameHistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String _teamName(String teamId) => GameTeams.byId(teamId)?.name ?? teamId;

  List<_PlayerAggregate> get _aggregates {
    final map = <String, _PlayerAggregate>{};
    for (final entry in _history) {
      for (final p in entry.players) {
        final key = p.rosterId ?? p.name;
        final agg = map.putIfAbsent(
          key,
          () => _PlayerAggregate(key: key, displayName: p.name),
        );
        agg.displayName = p.name;
        agg.games += 1;
        if (p.wasOnWinningSide) agg.wins += 1;
        agg.disciplineScore += p.disciplineStage;
        agg.totalScoreSum += p.totalScore;
        agg.challengesGivenTotal += p.challengesGiven;
        agg.challengesReceivedTotal += p.challengesReceived;
        agg.totalSpeakingSeconds += p.totalSpeakingSeconds;
        final role = p.roleId != null ? GameRoles.byId(p.roleId!) : null;
        agg.rows.add(
          _PlayerGameRow(
            playedAt: entry.playedAt,
            teamName: _teamName(p.teamId),
            roleName: role?.name,
            won: p.wasOnWinningSide,
            disciplineStage: p.disciplineStage,
            score: p.totalScore,
          ),
        );
      }
    }
    final list = map.values.toList()..sort((a, b) => b.wins.compareTo(a.wins));
    return list;
  }

  /// برایِ هر نقشی که تو role_success_metric.dart معیار داره، کسی که تو
  /// کلِ تاریخچه (رویِ همه‌ی بازی‌هایی که همون نقش رو بازی کرده) بیشترین
  /// تعدادِ رویدادِ امتیازیِ موفقِ متناظر با اون نقش رو داشته.
  List<_RoleBest> get _bestPerRole {
    final counts = <String, Map<String, int>>{}; // roleId -> playerKey -> count
    final displayNames = <String, String>{}; // playerKey -> آخرین اسمِ دیده‌شده
    final metricsByRoleId = <String, RoleSuccessMetric>{};
    for (final entry in _history) {
      for (final p in entry.players) {
        if (p.roleId == null) continue;
        final scenario = GameScenarios.byId(entry.scenarioId);
        if (scenario == null) continue;
        final metric = roleSuccessMetricsForScenario(scenario)[p.roleId];
        if (metric == null) continue;
        metricsByRoleId[p.roleId!] = metric;
        final key = p.rosterId ?? p.name;
        displayNames[key] = p.name;
        final successCount = p.scoreEvents
            .where((e) => e.points > 0 && metric.mechanisms.any((m) => e.mechanism.contains(m)))
            .length;
        if (successCount == 0) continue;
        final roleMap = counts.putIfAbsent(p.roleId!, () => {});
        roleMap[key] = (roleMap[key] ?? 0) + successCount;
      }
    }
    final result = <_RoleBest>[];
    for (final roleEntry in counts.entries) {
      if (roleEntry.value.isEmpty) continue;
      final role = GameRoles.byId(roleEntry.key);
      if (role == null) continue;
      final rankings = roleEntry.value.entries
          .map((e) => _RoleRanking(playerName: displayNames[e.key] ?? e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      result.add(_RoleBest(
        roleName: role.name,
        unitLabel: metricsByRoleId[roleEntry.key]!.unitLabel,
        rankings: rankings,
      ));
    }
    result.sort((a, b) => a.roleName.compareTo(b.roleName));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('آمار'.tr)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('آمار'.tr)),
        body: Center(
          child: Text(
            'هنوز هیچ بازی‌ای ثبت نشده.\nبعدِ تمام‌شدنِ اولین بازی، آمار همینجا نشون داده می‌شه.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    final aggregates = _aggregates;
    final lastGame = _history.first;
    final winner = lastGame.players.where((p) => p.wasOnWinningSide).toList();
    final loser = lastGame.players.where((p) => !p.wasOnWinningSide).toList();
    final undisciplined = aggregates.where((a) => a.disciplineScore > 0).toList()
      ..sort((a, b) => b.disciplineScore.compareTo(a.disciplineScore));
    final mostUndisciplined = undisciplined.isEmpty ? null : undisciplined.first;

    final scoredLastGame = lastGame.players.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final bestOfLastGame = scoredLastGame.isEmpty ? null : scoredLastGame.first;
    final worstOfLastGame = scoredLastGame.isEmpty ? null : scoredLastGame.last;
    final scoreLeaderboard = aggregates.toList()
      ..sort((a, b) => b.avgScore.compareTo(a.avgScore));
    final overallBest = scoreLeaderboard.isEmpty ? null : scoreLeaderboard.first;
    final overallWorst = scoreLeaderboard.isEmpty ? null : scoreLeaderboard.last;

    final byChallengesGiven = aggregates.where((a) => a.challengesGivenTotal > 0).toList()
      ..sort((a, b) => b.challengesGivenTotal.compareTo(a.challengesGivenTotal));
    final topChallengeGiver = byChallengesGiven.isEmpty ? null : byChallengesGiven.first;
    final byChallengesReceived = aggregates.where((a) => a.challengesReceivedTotal > 0).toList()
      ..sort((a, b) => b.challengesReceivedTotal.compareTo(a.challengesReceivedTotal));
    final topChallengeReceiver = byChallengesReceived.isEmpty ? null : byChallengesReceived.first;
    final speakingLeaderboard = aggregates.toList()
      ..sort((a, b) => b.totalSpeakingSeconds.compareTo(a.totalSpeakingSeconds));
    final mostTalkative = speakingLeaderboard.isEmpty ? null : speakingLeaderboard.first;
    final leastTalkative = speakingLeaderboard.isEmpty ? null : speakingLeaderboard.last;
    String formatSpeakingTime(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      if (minutes == 0) return '$secs ثانیه';
      return '$minutes دقیقه و $secs ثانیه';
    }
    final bestPerRole = _bestPerRole;

    return Scaffold(
      appBar: AppBar(
        title: Text('آمار و عملکرد'.tr),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Text('${_history.length} بازی',
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _StatsHero(historyCount: _history.length, playerCount: aggregates.length),
          SizedBox(height: 18),
          _sectionTitle('نتیجه‌ی آخرین بازی'),
          SizedBox(height: 10),
          Row(
            children: [
              if (winner.isNotEmpty)
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.emoji_events,
                    color: AppTheme.uiPrimary,
                    title: 'طرفِ برنده',
                    playerName: winner.map((p) => p.name).join('، '),
                    reason: _teamName(lastGame.winningTeamId),
                  ),
                ),
              if (winner.isNotEmpty && loser.isNotEmpty) SizedBox(width: 12),
              if (loser.isNotEmpty)
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.sentiment_dissatisfied,
                    color: AppColors.bloodRedLight,
                    title: 'طرفِ بازنده',
                    playerName: '${loser.length} نفر',
                    reason: 'حذف‌شده‌ها: ${loser.where((p) => !p.survived).length} نفر',
                  ),
                ),
            ],
          ),
          if (bestOfLastGame != null && worstOfLastGame != null && bestOfLastGame != worstOfLastGame) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.star,
                    color: AppTheme.uiPrimary,
                    title: 'بهترین بازیکنِ این بازی',
                    playerName: bestOfLastGame.name,
                    reason: 'امتیاز: ${bestOfLastGame.totalScore >= 0 ? '+' : ''}${bestOfLastGame.totalScore}',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.sentiment_very_dissatisfied,
                    color: AppColors.bloodRedLight,
                    title: 'بدترین بازیکنِ این بازی',
                    playerName: worstOfLastGame.name,
                    reason:
                        'امتیاز: ${worstOfLastGame.totalScore >= 0 ? '+' : ''}${worstOfLastGame.totalScore}',
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 28),
          SizedBox(height: 14),
          _sectionTitle('آمارِ کلِ بازی‌ها'),
          SizedBox(height: 4),
          Text(
            'روی مجموعِ ${_history.length} بازیِ ثبت‌شده.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          if (overallBest != null && overallWorst != null && overallBest.key != overallWorst.key)
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.star,
                    color: AppTheme.uiPrimary,
                    title: 'بهترین بازیکن (کلِ تاریخچه)',
                    playerName: overallBest.displayName,
                    reason: 'میانگینِ امتیاز: ${overallBest.avgScore >= 0 ? '+' : ''}'
                        '${overallBest.avgScore.toStringAsFixed(1)}',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.sentiment_very_dissatisfied,
                    color: AppColors.bloodRedLight,
                    title: 'بدترین بازیکن (کلِ تاریخچه)',
                    playerName: overallWorst.displayName,
                    reason: 'میانگینِ امتیاز: ${overallWorst.avgScore >= 0 ? '+' : ''}'
                        '${overallWorst.avgScore.toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
          if (mostUndisciplined != null) ...[
            SizedBox(height: 12),
            _HighlightCard(
              icon: Icons.gavel,
              color: AppColors.bloodRedLight,
              title: 'بی‌انضباط‌ترین بازیکن',
              playerName: mostUndisciplined.displayName,
              reason: 'نمره‌ی انضباطیِ تجمعی: ${mostUndisciplined.disciplineScore} '
                  '(مجموعِ مراحلِ تنبیه در همه‌ی بازی‌هاش)',
            ),
          ],
          if (mostTalkative != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.record_voice_over,
                    color: AppTheme.uiPrimary,
                    title: 'پُرحرف‌ترین بازیکن',
                    playerName: mostTalkative.displayName,
                    reason: formatSpeakingTime(mostTalkative.totalSpeakingSeconds),
                  ),
                ),
                if (leastTalkative != null && leastTalkative.key != mostTalkative.key) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.volume_off_outlined,
                      color: AppColors.bloodRedLight,
                      title: 'کم‌حرف‌ترین بازیکن',
                      playerName: leastTalkative.displayName,
                      reason: formatSpeakingTime(leastTalkative.totalSpeakingSeconds),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (topChallengeReceiver != null || topChallengeGiver != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                if (topChallengeReceiver != null)
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.record_voice_over,
                      color: AppTheme.uiPrimaryLight,
                      title: 'چالش‌بگیرترین بازیکن',
                      playerName: topChallengeReceiver.displayName,
                      reason: '${topChallengeReceiver.challengesReceivedTotal} بار چالش گرفته',
                    ),
                  ),
                if (topChallengeReceiver != null && topChallengeGiver != null)
                  SizedBox(width: 12),
                if (topChallengeGiver != null)
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.campaign,
                      color: AppTheme.uiPrimaryLight,
                      title: 'چالش‌بده‌ترین بازیکن',
                      playerName: topChallengeGiver.displayName,
                      reason: '${topChallengeGiver.challengesGivenTotal} بار چالش داده',
                    ),
                  ),
              ],
            ),
          ],
          if (bestPerRole.isNotEmpty) ...[
            SizedBox(height: 20),
            Text('بهترین‌هایِ هر نقش', style: AppTheme.headingFont(size: 16)),
            SizedBox(height: 4),
            Text(
              'بر اساسِ تعدادِ کارهایِ موفقِ اون نقش، رویِ مجموعِ همه‌ی بازی‌هایی که '
              'کسی اون نقش رو بازی کرده.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            SizedBox(height: 8),
            ...bestPerRole.map((r) => _RoleBestRow(best: r)),
          ],
          SizedBox(height: 28),
          SizedBox(height: 14),
          _sectionTitle('جدول رتبه‌بندی'),
          SizedBox(height: 10),
          ...aggregates.map((agg) => _LeaderboardRow(agg: agg)),
          SizedBox(height: 28),
          SizedBox(height: 14),
          _sectionTitle('میانگینِ امتیاز بازیکنان'),
          SizedBox(height: 4),
          Text(
            'میانگینِ امتیازِ هر بازیکن رو کلِ بازی‌هاش (طبقِ سیستمِ امتیازدهیِ رأی/شات/'
            'سلاخی/نجات/استعلام/انضباط و بقیه‌ی قابلیت‌ها).',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          ...scoreLeaderboard.map((agg) => _ScoreLeaderboardRow(agg: agg)),
          SizedBox(height: 28),
          SizedBox(height: 14),
          _sectionTitle('تاریخچه‌ی کامل هر بازیکن'),
          SizedBox(height: 4),
          Text(
            'با زدن روی هر بازیکن، لیستِ همه‌ی بازی‌هاش و نتیجه‌ی هرکدوم نشون داده می‌شه.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          ...aggregates.map(
            (agg) => Card(
              color: AppTheme.uiCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.uiPrimary.withAlpha(77)),
              ),
              margin: EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                collapsedIconColor: AppTheme.uiPrimary,
                iconColor: AppTheme.uiPrimary,
                title: Text(
                  agg.displayName,
                  style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${agg.games} بازی — ${agg.wins} برد',
                  style: TextStyle(color: Colors.white60),
                ),
                children: agg.rows
                    .map(
                      (row) => Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${formatJalali(row.playedAt)} — '
                            'نقش: ${row.roleName ?? row.teamName}، تیم: ${row.teamName}، '
                            '${row.won ? 'برنده' : 'بازنده'}'
                            '${row.disciplineStage > 0 ? '، ${disciplineStageLabel(row.disciplineStage)}' : ''}'
                            '، امتیاز: ${row.score >= 0 ? '+' : ''}${row.score}',
                            style: TextStyle(color: Colors.white70, height: 1.6),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsHero extends StatelessWidget {
  final int historyCount;
  final int playerCount;
  _StatsHero({required this.historyCount, required this.playerCount});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.uiCard,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppTheme.uiPrimary.withAlpha(51)),
      gradient: LinearGradient(
        colors: [AppTheme.uiCard, AppTheme.uiElevated],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    child: Row(children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: AppTheme.uiPrimaryDark.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.insights_rounded, color: AppTheme.uiPrimaryLight, size: 28),
      ),
      SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرکز آمار', style: AppTheme.headingFont(size: 21)),
          SizedBox(height: 4),
          Text('$historyCount بازی ثبت‌شده • $playerCount بازیکن',
            style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
        ],
      )),
    ]),
  );
}

Widget _sectionTitle(String text) => Padding(
  padding: EdgeInsetsDirectional.only(start: 2),
  child: Text(text, style: AppTheme.headingFont(size: 20)),
);

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String playerName;
  final String reason;

  _HighlightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.playerName,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(179)),
        color: AppTheme.uiCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final _PlayerAggregate agg;
  _LeaderboardRow({required this.agg});

  @override
  Widget build(BuildContext context) {
    final rate = agg.games == 0 ? 0 : ((agg.wins / agg.games) * 100).round();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.uiPrimary.withAlpha(51),
            child: Text(
              agg.displayName.isNotEmpty ? agg.displayName.substring(0, 1) : '?',
              style: TextStyle(color: AppTheme.uiPrimaryLight),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(agg.displayName, style: TextStyle(color: Colors.white)),
          ),
          Text('${agg.games} بازی', style: TextStyle(color: Colors.white60)),
          SizedBox(width: 12),
          Text('$rate% برد', style: TextStyle(color: AppTheme.uiPrimaryLight)),
        ],
      ),
    );
  }
}

class _ScoreLeaderboardRow extends StatelessWidget {
  final _PlayerAggregate agg;
  _ScoreLeaderboardRow({required this.agg});

  @override
  Widget build(BuildContext context) {
    final avg = agg.avgScore;
    final color = avg > 0
        ? AppTheme.uiPrimary
        : (avg < 0 ? AppColors.bloodRedLight : Colors.white60);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(51),
            child: Text(
              agg.displayName.isNotEmpty ? agg.displayName.substring(0, 1) : '?',
              style: TextStyle(color: color),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(agg.displayName, style: TextStyle(color: Colors.white)),
          ),
          Text('${agg.games} بازی', style: TextStyle(color: Colors.white60)),
          SizedBox(width: 12),
          Text(
            '${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(1)} میانگین',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
