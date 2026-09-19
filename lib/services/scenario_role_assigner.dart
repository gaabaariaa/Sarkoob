import '../models/game_session.dart';
import '../models/scenario.dart';

/// موتور عمومیِ تخصیصِ تیم و نقش برای هر سناریو.
///
/// این کلاس عمداً هیچ شناختی از «سرکوب» یا «مافیا» ندارد؛
/// سناریو فقط قراردادِ تیم‌ها، نقشِ ساده و رهبرِ مستقل را تأمین می‌کند.
class ScenarioRoleAssigner {
  static List<SessionPlayer> assign({
    required GameScenario scenario,
    required List<String> playerNames,
    required List<String?> rosterIds,
    required int leaderCount,
    required int independentCount,
    required List<String> leaderRoleIds,
    required List<String> townRoleIds,
    required bool independentEnabled,
  }) {
    if (playerNames.length != rosterIds.length) {
      throw ArgumentError('playerNames and rosterIds must have the same length');
    }

    final total = playerNames.length;
    if (leaderCount < 0 ||
        independentCount < 0 ||
        leaderCount + independentCount > total) {
      throw ArgumentError('Invalid team counts for scenario ' + scenario.id);
    }

    final allShuffled = List<int>.generate(total, (i) => i)..shuffle();
    final leaderIndices = allShuffled.take(leaderCount).toSet();
    final independentIndices = allShuffled
        .skip(leaderCount)
        .take(independentCount)
        .toSet();

    final leaderShuffled = leaderIndices.toList()..shuffle();
    final townShuffled = List<int>.generate(total, (i) => i)
        .where(
          (i) =>
              !leaderIndices.contains(i) && !independentIndices.contains(i),
        )
        .toList()
      ..shuffle();

    final independentShuffled = independentIndices.toList()..shuffle();
    final roleByIndex = <int, String>{};

    var leaderCursor = 0;
    for (final roleId in leaderRoleIds) {
      if (leaderCursor >= leaderShuffled.length) break;
      roleByIndex[leaderShuffled[leaderCursor++]] = roleId;
    }

    var townCursor = 0;
    for (final roleId in townRoleIds) {
      if (townCursor >= townShuffled.length) break;
      roleByIndex[townShuffled[townCursor++]] = roleId;
    }

    if (independentEnabled &&
        independentShuffled.isNotEmpty &&
        scenario.independentLeaderRoleId.isNotEmpty) {
      roleByIndex[independentShuffled.first] =
          scenario.independentLeaderRoleId;
    }

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (leaderIndices.contains(i)) {
        teamId = scenario.leaderTeamId;
      } else if (independentIndices.contains(i)) {
        teamId = scenario.independentTeamId;
      } else {
        teamId = scenario.townTeamId;
      }

      var roleId = roleByIndex[i];
      roleId ??= teamId == scenario.leaderTeamId
          ? scenario.leaderDefaultRoleId
          : teamId == scenario.townTeamId
              ? scenario.townDefaultRoleId
              : null;

      players.add(
        SessionPlayer(
          id: i + 1,
          name: playerNames[i],
          rosterId: rosterIds[i],
          teamId: teamId,
          roleId: roleId,
        ),
      );
    }

    return players;
  }
}
