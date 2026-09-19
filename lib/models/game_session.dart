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