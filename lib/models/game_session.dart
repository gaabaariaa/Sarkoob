/// فازهای کلی یه جلسه‌ی بازی.
enum GamePhaseType {
  introDay, // روز معارفه
  introNight, // شب معارفه (فقط سرکوب بجز مدیری)
  day, // روزهای عادی (۱، ۲، ...)
  night, // شب‌های عادی — منطقش بعد از تعریف نقش‌ها تکمیل می‌شه
}

/// تنظیمات زمان‌بندی؛ طبق قانون گفته‌شده، زمان معارفه و چالش همیشه
/// نصف زمان صحبته (مستقل تنظیم نمی‌شن).
class GameSettings {
  final int speakSeconds;

  const GameSettings({this.speakSeconds = 60});

  int get introSeconds => (speakSeconds / 2).round();
  int get challengeSeconds => (speakSeconds / 2).round();

  GameSettings copyWith({int? speakSeconds}) {
    return GameSettings(speakSeconds: speakSeconds ?? this.speakSeconds);
  }
}

/// بازیکنِ همین جلسه‌ی بازی (نه لیست دائمی).
/// teamId فعلاً موقتی و دستی‌ست، تا وقتی موتور تقسیم نقش واقعی ساخته بشه.
class SessionPlayer {
  final int id;
  final String name;
  bool isAlive;
  int recordCount; // «سابقه»
  String teamId; // یکی از شناسه‌های GameTeam (team_sorkoob / team_citizen / ...)
  bool isModiri;
  int votes;
  bool challengeUsedToday;
  bool hasSpokenThisRound;

  // ---- مربوط به نقش (فعلاً فقط ولی‌فقیه از این‌ها استفاده می‌کنه) ----
  String? roleId;
  bool hasArmor;
  int? slaughterChargesRemaining;
  bool eliminatedBySlaughter; // برای اینکه بعداً حتی ستوده هم نتونه برش گردونه

  SessionPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    this.isAlive = true,
    this.recordCount = 0,
    this.isModiri = false,
    this.votes = 0,
    this.challengeUsedToday = false,
    this.hasSpokenThisRound = false,
    this.roleId,
    this.hasArmor = false,
    this.slaughterChargesRemaining,
    this.eliminatedBySlaughter = false,
  });

  bool get isSorkoobTeam => teamId == 'team_sorkoob';
}
