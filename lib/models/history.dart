import 'dart:convert';
import 'score_event.dart';

/// یه بازیکنِ ثابت تو لیستِ دائمیِ گرداننده — برای این‌که موقعِ شروعِ
/// بازیِ جدید، لازم نباشه دوباره اسم‌ها رو تایپ کنه.
class SavedPlayerProfile {
  final String id;
  String name;

  SavedPlayerProfile({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory SavedPlayerProfile.fromJson(Map<String, dynamic> json) {
    return SavedPlayerProfile(id: json['id'] as String, name: json['name'] as String);
  }
}

/// وضعیتِ یه بازیکنِ خاص در یه بازیِ تمام‌شده — برای تاریخچه و آمار.
class GameHistoryPlayerRecord {
  final String? rosterId; // اگه از لیستِ دائمی انتخاب شده بود
  final String name;
  final String teamId;
  final String? roleId;
  final bool survived; // تا آخرِ بازی زنده موند؟
  final bool wasOnWinningSide;
  final int disciplineStage; // ۰-۴؛ آخرین مرحله‌ی تنبیهِ انضباطیِ این بازیکن تو این بازی
  final int totalScore; // جمعِ امتیازِ این بازیکن تو این بازی (سندِ طراحیِ امتیازدهی)
  final int challengesGiven; // کلِ چالش‌هایی که این بازیکن تو کلِ همین بازی داد
  final int challengesReceived; // کلِ چالش‌هایی که این بازیکن تو کلِ همین بازی گرفت
  final List<ScoreEvent> scoreEvents; // ریزِ رویدادهایِ امتیازی — برایِ «بهترینِ هر نقش» و جزئیات

  GameHistoryPlayerRecord({
    this.rosterId,
    required this.name,
    required this.teamId,
    this.roleId,
    required this.survived,
    required this.wasOnWinningSide,
    this.disciplineStage = 0,
    this.totalScore = 0,
    this.challengesGiven = 0,
    this.challengesReceived = 0,
    this.scoreEvents = const [],
  });

  Map<String, dynamic> toJson() => {
        'rosterId': rosterId,
        'name': name,
        'teamId': teamId,
        'roleId': roleId,
        'survived': survived,
        'wasOnWinningSide': wasOnWinningSide,
        'disciplineStage': disciplineStage,
        'totalScore': totalScore,
        'challengesGiven': challengesGiven,
        'challengesReceived': challengesReceived,
        'scoreEvents': scoreEvents.map((e) => e.toJson()).toList(),
      };

  factory GameHistoryPlayerRecord.fromJson(Map<String, dynamic> json) {
    return GameHistoryPlayerRecord(
      rosterId: json['rosterId'] as String?,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      roleId: json['roleId'] as String?,
      survived: json['survived'] as bool,
      wasOnWinningSide: json['wasOnWinningSide'] as bool,
      // فیلدهایِ جدید؛ رکوردهایِ قدیمی‌ترِ ذخیره‌شده این کلیدها رو ندارن،
      // پس پیش‌فرضِ خالی/صفر.
      disciplineStage: json['disciplineStage'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      challengesGiven: json['challengesGiven'] as int? ?? 0,
      challengesReceived: json['challengesReceived'] as int? ?? 0,
      scoreEvents: json['scoreEvents'] == null
          ? const []
          : (json['scoreEvents'] as List)
              .map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// یه رکوردِ کاملِ یه بازیِ تمام‌شده: کِی بازی شد، کی برد، و هرکس چه
/// تیم/نقشی داشت و زنده موند یا نه.
class GameHistoryEntry {
  final String id;
  final DateTime playedAt;
  final String winningTeamId; // شناسه‌ی تیمِ برنده، یا 'unknown'
  final List<GameHistoryPlayerRecord> players;

  GameHistoryEntry({
    required this.id,
    required this.playedAt,
    required this.winningTeamId,
    required this.players,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'winningTeamId': winningTeamId,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      id: json['id'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      winningTeamId: json['winningTeamId'] as String,
      players: (json['players'] as List)
          .map((p) => GameHistoryPlayerRecord.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

String encodeHistoryList(List<GameHistoryEntry> list) {
  return jsonEncode(list.map((e) => e.toJson()).toList());
}

List<GameHistoryEntry> decodeHistoryList(String raw) {
  final decoded = jsonDecode(raw) as List;
  return decoded.map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
}

String encodeRosterList(List<SavedPlayerProfile> list) {
  return jsonEncode(list.map((e) => e.toJson()).toList());
}

List<SavedPlayerProfile> decodeRosterList(String raw) {
  final decoded = jsonDecode(raw) as List;
  return decoded.map((e) => SavedPlayerProfile.fromJson(e as Map<String, dynamic>)).toList();
}
