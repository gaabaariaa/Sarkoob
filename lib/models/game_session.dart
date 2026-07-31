/// فازهای کلی یه جلسه‌ی بازی.
enum GamePhaseType {
  introDay, // روز معارفه
  introNight, // شب معارفه (فقط سرکوب بجز مدیری)
  day, // روزهای عادی (۱، ۲، ...)
  night, // شب‌های عادی
}

/// تنظیمات زمان‌بندی؛ طبق قانون گفته‌شده، زمان معارفه و چالش همیشه
/// نصف زمان صحبته (مستقل تنظیم نمی‌شن).
class GameSettings {
  final int speakSeconds;

  /// چندبار در کلِ بازی دکتر می‌تونه خودش رو نجات بده (پیش‌فرض ۲).
  final int doctorMaxSelfSaves;

  const GameSettings({this.speakSeconds = 60, this.doctorMaxSelfSaves = 2});

  int get introSeconds => (speakSeconds / 2).round();
  int get challengeSeconds => (speakSeconds / 2).round();

  GameSettings copyWith({int? speakSeconds, int? doctorMaxSelfSaves}) {
    return GameSettings(
      speakSeconds: speakSeconds ?? this.speakSeconds,
      doctorMaxSelfSaves: doctorMaxSelfSaves ?? this.doctorMaxSelfSaves,
    );
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

  // ---- مربوط به رئیس قوه قضاییه ----
  bool executionOrderUsed; // آیا قابلیتِ یک‌بارمصرفش رو مصرف کرده؟
  bool isHalfAlive; // نیمه‌جان: تا وقتی «وکیل مردمی» نجاتش بده، شب‌ها بیدار نمی‌شه

  // ---- مربوط به دکتر ----
  int selfSavesUsed; // چندبار تا الان خودش رو نجات داده (سقفش تو GameSettings ـه)

  // ---- مربوط به مبارزِ انقلابی ----
  int? revolutionaryChargesRemaining; // سهمیه‌ی مشترکِ اعدامِ انقلابی/سلاخی
  bool canStillSlaughter; // بعدِ یه حدسِ غلط، برای همیشه false می‌شه

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
    this.executionOrderUsed = false,
    this.isHalfAlive = false,
    this.selfSavesUsed = 0,
    this.revolutionaryChargesRemaining,
    this.canStillSlaughter = true,
  });

  bool get isSorkoobTeam => teamId == 'team_sorkoob';
}
