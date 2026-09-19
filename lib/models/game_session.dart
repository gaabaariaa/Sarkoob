import 'role.dart';
import 'score_event.dart';

/// برچسبِ فارسیِ هر مرحله‌ی تنبیهِ انضباطیِ گرداننده — هم تو خودِ بازی
/// (دیالوگِ تنبیه) و هم تو آمار/تاریخچه (بعدِ تمومِ بازی) استفاده می‌شه،
/// برای همینم یه تابعِ مشترکه، نه چیزی که تو هر صفحه جدا نوشته بشه.
/// ۰=بدونِ سابقه، ۱=اخطار، ۲=منعِ یک‌روزه‌ی چالش‌گرفتن، ۳=منعِ همیشگیِ
/// چالش‌گرفتن + سکوتِ همون‌روز، ۴ به‌بالا=اخراج (چه از همین مسیر چه اخراجِ مستقیم).
String disciplineStageLabel(int stage) {
  switch (stage) {
    case 0:
      return 'بدونِ سابقه';
    case 1:
      return 'اخطار گرفته';
    case 2:
      return 'یک‌روز از چالش‌گرفتن منع شده';
    case 3:
      return 'برای‌همیشه از چالش‌گرفتن منع شده و سکوتِ انضباطی خورده';
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
  /// سناریوی صریحِ همین جلسه؛ منبع حقیقت سناریو در کل Game Flow.
  final String scenarioId;

  final int speakSeconds;

  /// چندبار در کلِ بازی دکتر می‌تونه خودش رو نجات بده (پیش‌فرض ۲).
  final int doctorMaxSelfSaves;

  /// محلِ برگزاریِ بازی — متنِ آزادِ گرداننده، می‌تونه خالی بمونه.
  final String location;

  const GameSettings({
    this.scenarioId = 'scenario_sorkoob',
    this.speakSeconds = 60,
    this.doctorMaxSelfSaves = 2,
    this.location = '',
  });

  int get introSeconds => (speakSeconds / 2).round();
  int get challengeSeconds => (speakSeconds / 2).round();

  GameSettings copyWith({String? scenarioId, int? speakSeconds, int? doctorMaxSelfSaves, String? location}) {
    return GameSettings(
      scenarioId: scenarioId ?? this.scenarioId,
      speakSeconds: speakSeconds ?? this.speakSeconds,
      doctorMaxSelfSaves: doctorMaxSelfSaves ?? this.doctorMaxSelfSaves,
      location: location ?? this.location,
    );
  }
}

/// بازیکنِ همین جلسه‌ی بازی (نه لیست دائمی).
/// teamId فعلاً موقتی و دستی‌ست، تا وقتی موتور تقسیم نقش واقعی ساخته بشه.
class SessionPlayer {
  final int id;
  final String name;
  final String? rosterId;
  bool isAlive;
  int recordCount;
  String teamId;
  bool isModiri;
  int votes;
  bool challengeReceivedToday;
  bool challengeGivenToday;
  int challengesGivenTotal = 0;
  int challengesReceivedTotal = 0;
  bool hasSpokenThisRound;
  String? roleId;
  bool hasArmor;
  int? slaughterChargesRemaining;
  bool eliminatedBySlaughter;
  bool executionOrderUsed;
  bool isHalfAlive;
  int selfSavesUsed;
  int? revolutionaryChargesRemaining;
  bool canStillSlaughter;
  bool revivalUsed;
  bool isActiveResistanceMember;
  GunType? heldGunType;
  int? warGunsRemaining;
  int? intelQuestionsRemaining;
  int? guaranteesRemaining;
  bool interrogationUsed;
  bool natashaSilenceUsed;
  MossadPlaystyle? mossadPlaystyle;
  bool referendumUsed;
  bool negotiateUsed;
  int disciplineStage;
  int? challengeBanRoundNumber;
  bool challengeBannedForever;
  int? silencedRoundNumber;
  int? noVoteRightsRoundNumber;
  final List<ScoreEvent> scoreEvents = [];

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
    this.natashaSilenceUsed = false,
    this.mossadPlaystyle,
    this.referendumUsed = false,
    this.negotiateUsed = false,
    this.disciplineStage = 0,
    this.challengeBanRoundNumber,
    this.challengeBannedForever = false,
    this.silencedRoundNumber,
    this.noVoteRightsRoundNumber,
  });

  bool get isSorkoobTeam => teamId == 'team_sorkoob';

  int get scoreTotal => scoreEvents.fold(0, (sum, e) => sum + e.points);
}
