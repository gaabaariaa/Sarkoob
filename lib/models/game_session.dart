import 'role.dart';

/// برچسبِ فارسیِ هر مرحله‌ی تنبیهِ انضباطیِ گرداننده — هم تو خودِ بازی
/// (دیالوگِ تنبیه) و هم تو آمار/تاریخچه (بعدِ تمومِ بازی) استفاده می‌شه،
/// برای همینم یه تابعِ مشترکه، نه چیزی که تو هر صفحه جدا نوشته بشه.
/// ۰=بدونِ سابقه، ۱=اخطار، ۲=منعِ یک‌روزه‌ی چالش، ۳=منعِ همیشگیِ چالش +
/// سکوتِ همون‌روز، ۴ به‌بالا=اخراج (چه از همین مسیر چه اخراجِ مستقیم).
String disciplineStageLabel(int stage) {
  switch (stage) {
    case 0:
      return 'بدونِ سابقه';
    case 1:
      return 'اخطار گرفته';
    case 2:
      return 'یک‌روز از چالش‌دادن منع شده';
    case 3:
      return 'برای‌همیشه از چالش‌دادن منع شده و سکوتِ انضباطی خورده';
    default:
      return 'از بازی اخراج شده';
  }
}

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
  final String? rosterId; // اگه از لیستِ دائمیِ بازیکن‌ها انتخاب شده بود
  bool isAlive;
  int recordCount; // «سابقه»
  String teamId; // یکی از شناسه‌های GameTeam (team_sorkoob / team_citizen / ...)
  bool isModiri;
  int votes;
  bool challengeReceivedToday; // آیا امروز قبلاً هدفِ چالش قرار گرفته؟
  bool challengeGivenToday; // آیا تو نوبتِ عادیِ امروزش قبلاً به کسی چالش داده؟
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

  // ---- مربوط به وکیل ----
  bool revivalUsed; // آیا قابلیتِ یک‌بارمصرفِ جان‌بخشی رو مصرف کرده؟

  // ---- مربوط به رپر معترض ----
  bool isActiveResistanceMember; // عضوِ فعالِ تیمِ مقاومتِ رپر معترضه؟

  // ---- مربوط به شورشی و اسلحه ----
  GunType? heldGunType; // اسلحه‌ای که همین الان دستشه (null یعنی نداره)
  int? warGunsRemaining; // فقط رو خودِ شورشی: سهمیه‌ی کلِ اسلحه‌ی جنگی

  // ---- مربوط به وزیر اطلاعات ----
  int? intelQuestionsRemaining; // سهمیه‌ی کلِ سؤالِ اطلاعاتی در طولِ بازی

  // ---- مربوط به قهرمان ملی ----
  int? guaranteesRemaining; // سهمیه‌ی کلِ تضمین در طولِ بازی

  // ---- مربوط به بازجو خبرنگار ----
  bool interrogationUsed; // آیا قابلیتِ یک‌بارمصرفِ بازجویی رو مصرف کرده؟

  // ---- مربوط به رهبر موساد ----
  MossadPlaystyle? mossadPlaystyle; // شبِ اول انتخاب می‌شه، بعدش ثابت می‌مونه

  // ---- مربوط به فعال مدنی ----
  bool referendumUsed; // آیا قابلیتِ یک‌بارمصرفِ درخواستِ رفراندوم رو مصرف کرده؟

  // ---- مربوط به تنبیهِ انضباطیِ گرداننده ----
  int disciplineStage; // ۰=بدونِ سابقه، ۱=اخطار، ۲=منعِ یک‌روزه، ۳=منعِ همیشگی+سکوت، ۴=اخراج
  int? challengeBanRoundNumber; // فقط برای منعِ یک‌روزه‌ی مرحله‌ی ۲: کدوم روز نمی‌تونه چالش بده
  bool challengeBannedForever; // از مرحله‌ی ۳ به بعد، برای همیشه
  int? silencedRoundNumber; // فقط برای مرحله‌ی ۳: کدوم روز باید نوبتِ صحبتش رد بشه

  SessionPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    this.rosterId,
    this.isAlive = true,
    this.recordCount = 0,
    this.isModiri = false,
    this.votes = 0,
    this.challengeReceivedToday = false,
    this.challengeGivenToday = false,
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
    this.revivalUsed = false,
    this.isActiveResistanceMember = false,
    this.heldGunType,
    this.warGunsRemaining,
    this.intelQuestionsRemaining,
    this.guaranteesRemaining,
    this.interrogationUsed = false,
    this.mossadPlaystyle,
    this.referendumUsed = false,
    this.disciplineStage = 0,
    this.challengeBanRoundNumber,
    this.challengeBannedForever = false,
    this.silencedRoundNumber,
  });

  bool get isSorkoobTeam => teamId == 'team_sorkoob';
}
