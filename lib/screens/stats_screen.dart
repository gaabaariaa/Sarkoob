import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/role_success_metric.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

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

class _RoleBest {
  final String roleName;
  final String playerName;
  final int count;
  final String unitLabel;
  const _RoleBest({
    required this.roleName,
    required this.playerName,
    required this.count,
    required this.unitLabel,
  });
}

class _RoleBestRow extends StatelessWidget {
  final _RoleBest best;
  const _RoleBestRow({required this.best});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                children: [
                  TextSpan(
                    text: 'بهترین ${best.roleName}: ',
                    style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${best.playerName} با ${best.count} ${best.unitLabel}'),
                ],
              ),
            ),
          ),
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

  String _teamName(String teamId) => SarkoobTeams.byId(teamId)?.name ?? teamId;

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
        final role = p.roleId != null ? SarkoobRoles.byId(p.roleId!) : null;
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
    for (final entry in _history) {
      for (final p in entry.players) {
        if (p.roleId == null) continue;
        final metric = roleSuccessMetrics[p.roleId];
        if (metric == null) continue;
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
      final best = roleEntry.value.entries.reduce((a, b) => b.value > a.value ? b : a);
      final role = SarkoobRoles.byId(roleEntry.key);
      if (role == null) continue;
      result.add(_RoleBest(
        roleName: role.name,
        playerName: displayNames[best.key] ?? best.key,
        count: best.value,
        unitLabel: roleSuccessMetrics[roleEntry.key]!.unitLabel,
      ));
    }
    result.sort((a, b) => a.roleName.compareTo(b.roleName));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('آمار')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('آمار')),
        body: const Center(
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
    final bestPerRole = _bestPerRole;

    return Scaffold(
      appBar: AppBar(title: const Text('آمار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('نتیجه‌ی آخرین بازی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (winner.isNotEmpty)
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.emoji_events,
                    color: AppColors.gold,
                    title: 'طرفِ برنده',
                    playerName: winner.map((p) => p.name).join('، '),
                    reason: _teamName(lastGame.winningTeamId),
                  ),
                ),
              if (winner.isNotEmpty && loser.isNotEmpty) const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.star,
                    color: AppColors.gold,
                    title: 'بهترین بازیکنِ این بازی',
                    playerName: bestOfLastGame.name,
                    reason: 'امتیاز: ${bestOfLastGame.totalScore >= 0 ? '+' : ''}${bestOfLastGame.totalScore}',
                  ),
                ),
                const SizedBox(width: 12),
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
          const SizedBox(height: 28),
          Text('آمارِ کلِ بازی‌ها', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          Text(
            'روی مجموعِ ${_history.length} بازیِ ثبت‌شده.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          if (overallBest != null && overallWorst != null && overallBest.key != overallWorst.key)
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    icon: Icons.star,
                    color: AppColors.gold,
                    title: 'بهترین بازیکن (کلِ تاریخچه)',
                    playerName: overallBest.displayName,
                    reason: 'میانگینِ امتیاز: ${overallBest.avgScore >= 0 ? '+' : ''}'
                        '${overallBest.avgScore.toStringAsFixed(1)}',
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            _HighlightCard(
              icon: Icons.gavel,
              color: AppColors.bloodRedLight,
              title: 'بی‌انضباط‌ترین بازیکن',
              playerName: mostUndisciplined.displayName,
              reason: 'نمره‌ی انضباطیِ تجمعی: ${mostUndisciplined.disciplineScore} '
                  '(مجموعِ مراحلِ تنبیه در همه‌ی بازی‌هاش)',
            ),
          ],
          if (topChallengeReceiver != null || topChallengeGiver != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (topChallengeReceiver != null)
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.record_voice_over,
                      color: AppColors.goldLight,
                      title: 'چالش‌بگیرترین بازیکن',
                      playerName: topChallengeReceiver.displayName,
                      reason: '${topChallengeReceiver.challengesReceivedTotal} بار چالش گرفته',
                    ),
                  ),
                if (topChallengeReceiver != null && topChallengeGiver != null)
                  const SizedBox(width: 12),
                if (topChallengeGiver != null)
                  Expanded(
                    child: _HighlightCard(
                      icon: Icons.campaign,
                      color: AppColors.goldLight,
                      title: 'چالش‌بده‌ترین بازیکن',
                      playerName: topChallengeGiver.displayName,
                      reason: '${topChallengeGiver.challengesGivenTotal} بار چالش داده',
                    ),
                  ),
              ],
            ),
          ],
          if (bestPerRole.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('بهترین‌هایِ هر نقش', style: AppTheme.headingFont(size: 16)),
            const SizedBox(height: 4),
            const Text(
              'بر اساسِ تعدادِ کارهایِ موفقِ اون نقش، رویِ مجموعِ همه‌ی بازی‌هایی که '
              'کسی اون نقش رو بازی کرده.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...bestPerRole.map((r) => _RoleBestRow(best: r)),
          ],
          const SizedBox(height: 28),
          Text('جدول رتبه‌بندی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 10),
          ...aggregates.map((agg) => _LeaderboardRow(agg: agg)),
          const SizedBox(height: 28),
          Text('بهترین/بدترین بازیکنان (میانگینِ امتیاز)', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'میانگینِ امتیازِ هر بازیکن رو کلِ بازی‌هاش (طبقِ سیستمِ امتیازدهیِ رأی/شات/'
            'سلاخی/نجات/استعلام/انضباط و بقیه‌ی قابلیت‌ها).',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ...scoreLeaderboard.map((agg) => _ScoreLeaderboardRow(agg: agg)),
          const SizedBox(height: 28),
          Text('تاریخچه‌ی کامل هر بازیکن', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'با زدن روی هر بازیکن، لیستِ همه‌ی بازی‌هاش و نتیجه‌ی هرکدوم نشون داده می‌شه.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ...aggregates.map(
            (agg) => Card(
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                collapsedIconColor: AppColors.gold,
                iconColor: AppColors.gold,
                title: Text(
                  agg.displayName,
                  style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${agg.games} بازی — ${agg.wins} برد',
                  style: const TextStyle(color: Colors.white60),
                ),
                children: agg.rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${row.playedAt.year}/${row.playedAt.month}/${row.playedAt.day} — '
                            'نقش: ${row.roleName ?? row.teamName}، تیم: ${row.teamName}، '
                            '${row.won ? 'برنده' : 'بازنده'}'
                            '${row.disciplineStage > 0 ? '، ${disciplineStageLabel(row.disciplineStage)}' : ''}'
                            '، امتیاز: ${row.score >= 0 ? '+' : ''}${row.score}',
                            style: const TextStyle(color: Colors.white70, height: 1.6),
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

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String playerName;
  final String reason;

  const _HighlightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.playerName,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.7)),
        color: AppColors.surfaceCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final _PlayerAggregate agg;
  const _LeaderboardRow({required this.agg});

  @override
  Widget build(BuildContext context) {
    final rate = agg.games == 0 ? 0 : ((agg.wins / agg.games) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withOpacity(0.2),
            child: Text(
              agg.displayName.isNotEmpty ? agg.displayName.substring(0, 1) : '?',
              style: const TextStyle(color: AppColors.goldLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(agg.displayName, style: const TextStyle(color: Colors.white)),
          ),
          Text('${agg.games} بازی', style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 12),
          Text('$rate% برد', style: const TextStyle(color: AppColors.goldLight)),
        ],
      ),
    );
  }
}

class _ScoreLeaderboardRow extends StatelessWidget {
  final _PlayerAggregate agg;
  const _ScoreLeaderboardRow({required this.agg});

  @override
  Widget build(BuildContext context) {
    final avg = agg.avgScore;
    final color = avg > 0
        ? AppColors.gold
        : (avg < 0 ? AppColors.bloodRedLight : Colors.white60);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              agg.displayName.isNotEmpty ? agg.displayName.substring(0, 1) : '?',
              style: TextStyle(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(agg.displayName, style: const TextStyle(color: Colors.white)),
          ),
          Text('${agg.games} بازی', style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 12),
          Text(
            '${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(1)} میانگین',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
