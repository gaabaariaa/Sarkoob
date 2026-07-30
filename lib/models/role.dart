import 'team.dart';

/// چه نوع تصمیم/اقدام شبانه‌ای این نقش داره؛ موتور بازی بر این اساس
/// می‌فهمه چه UI ای رو براش نشون بده.
enum NightActionKind {
  none,
  sorkoobLeaderDecision, // مخصوص ولی‌فقیه: تصمیم شات یا سلاخی
}

/// تعریف کامل یه نقش: اسم، تیم، توضیح، عکس کارت، و پرچم‌های قابلیت‌های خاص.
/// چون نقش‌های این سناریو خیلی به‌هم متفاوت و بسیار جزئی‌ان، به‌جای یه
/// سیستم «قابلیت عمومی»، فیلدهای اختصاصی روی خودِ نقش تعریف می‌شن.
class GameRole {
  final String id;
  final String name;
  final String teamId;
  final String description;

  /// فعلاً عکس‌ها موقتاً حذف شدن (برای کم‌کردن حجم)؛ بعداً که همه‌ی
  /// نقش‌ها آماده شدن، یه‌جا اضافه می‌شن. تا اون‌موقع همیشه null ـه.
  final String? imageAsset;

  final NightActionKind nightAction;

  // ---- فیلدهای مخصوص ولی‌فقیه ----
  final bool alwaysShowsInnocent; // استعلامش همیشه منفیه
  final bool hasNightArmor; // زره در شب
  final bool canSlaughter; // قابلیت سلاخی داره؟

  // ---- فیلدِ مخصوص وزیر امور خارجه ----
  final bool canNegotiate; // قابلیت اغفال/مذاکره داره؟

  // ---- فیلدِ مخصوص رئیس قوه قضاییه ----
  final bool canIssueExecutionOrder; // قابلیت صدور حکم اعدام داره؟

  // ---- فیلدِ مخصوص دکتر ----
  final bool canHeal; // قابلیتِ نجاتِ شبانه داره؟

  const GameRole({
    required this.id,
    required this.name,
    required this.teamId,
    required this.description,
    this.imageAsset,
    this.nightAction = NightActionKind.none,
    this.alwaysShowsInnocent = false,
    this.hasNightArmor = false,
    this.canSlaughter = false,
    this.canNegotiate = false,
    this.canIssueExecutionOrder = false,
    this.canHeal = false,
  });
}

/// کتابخونه‌ی نقش‌های سناریوی سرکوب — نقش‌ها یکی‌یکی این‌جا اضافه می‌شن.
class SarkoobRoles {
  static final valiFaghih = GameRole(
    id: 'role_vali_faghih',
    name: 'ولی فقیه',
    teamId: SarkoobTeams.suppression.id,
    description:
        'رهبر تیم سرکوب و تصمیم‌گیرنده‌ی نهایی. هر شب با تیم سرکوب بیدار می‌شه؛ '
        'بقیه‌ی اعضا نظر می‌دن، ولی فقط اون تصمیم نهایی رو می‌گیره: یا شاتِ '
        'تیمی، یا سلاخی — نه هر دو با هم. استعلامش همیشه بی‌گناه نشون داده '
        'می‌شه. یک زره داره: اولین شاتی که بهش بخوره فقط زره رو از بین می‌بره '
        '(خودش زنده می‌مونه)، ولی شاتِ بعدی — چه همون شب چه شب دیگه — حذفش '
        'می‌کنه، مگر اینکه دکتر همون شب نجاتش بده.',
    nightAction: NightActionKind.sorkoobLeaderDecision,
    alwaysShowsInnocent: true,
    hasNightArmor: true,
    canSlaughter: true,
  );

  static final foreignMinister = GameRole(
    id: 'role_foreign_minister',
    name: 'وزیر امور خارجه',
    teamId: SarkoobTeams.suppression.id,
    description:
        'پس از بیرون رفتنِ یکی از اعضای تیم سرکوب از بازی، فعال می‌شه. از اون '
        'به بعد، تیم سرکوب می‌تونه به‌جای شاتِ شبانه، از قابلیتِ «اغفال» '
        'استفاده کنه: یک شهروندِ خاکستری (بدون نقشِ خاص) رو انتخاب می‌کنن تا '
        'به تیم سرکوب اضافه بشه. اگه به‌جاش یه شهروندِ نقش‌دار یا عضوِ یه تیمِ '
        'مستقل رو انتخاب کنن، مذاکره شکست می‌خوره و اون شب فرصت از دست میره. '
        'مذاکره و تصمیمِ ولی‌فقیه (شات/سلاخی) در یک شب، فقط یکیشون قابل‌استفاده‌ست.',
    canNegotiate: true,
  );

  /// نقشی که یه شهروندِ خاکستری، بعد از مذاکره‌ی موفق، بهش تبدیل می‌شه.
  /// قابلیتِ خاصی نداره؛ فقط رسماً عضوِ تیم سرکوب می‌شه.
  static final suppressor = GameRole(
    id: 'role_suppressor',
    name: 'سرکوبگر',
    teamId: SarkoobTeams.suppression.id,
    description:
        'یه عضوِ ساده‌ی تیم سرکوبه؛ قابلیتِ خاصی نداره. معمولاً یا از اول '
        'همین نقش رو داشته، یا با موفقیتِ مذاکره‌ی وزیر امور خارجه، از یه '
        'شهروندِ خاکستری تبدیل شده به این نقش.',
  );

  static final judiciaryChief = GameRole(
    id: 'role_judiciary_chief',
    name: 'رئیس قوه قضاییه',
    teamId: SarkoobTeams.suppression.id,
    description:
        'یک‌بار در طول بازی، مستقل از تصمیمِ ولی‌فقیه، می‌تونه شب یه کلمه رو '
        'به گرداننده اعلام کنه. فردا صبح گرداننده اعلام می‌کنه که قوه‌ی '
        'قضاییه حکمِ اعدام صادر کرده و اون کلمه رو به همه می‌گه. اگه همون روز '
        '(قبل از شروعِ رأی‌گیری) هر بازیکنی اون کلمه رو به زبون بیاره، همون '
        'لحظه از بازی خارج می‌شه — حتی اگه خودش عضوِ تیم سرکوب باشه.',
    canIssueExecutionOrder: true,
  );

  static final doctor = GameRole(
    id: 'role_doctor',
    name: 'دکتر',
    teamId: SarkoobTeams.citizen.id,
    description:
        'هر شب می‌تونه یک یا چند بازیکن رو در برابر شاتِ شبِ تیم سرکوب نجات '
        'بده. ظرفیتِ هر شب به تعدادِ بازیکنانِ زنده‌ی همون‌موقع وابسته‌ست و هر '
        'شب از نو حساب می‌شه: تا ۱۱ نفر یک نجات، ۱۲ تا ۱۷ نفر دو نجات، ۱۸ تا '
        '۲۳ نفر سه نجات، و به همین ترتیب هر ۶ نفر یکی بیشتر. اگه هدفِ '
        'نجات‌داده‌شده هم‌زمان چند ضربه بخوره، نجات فقط جلوی یکی از ضربه‌ها '
        'رو می‌گیره، نه همه‌شون. می‌تونه هر بازیکنی رو نجات بده — حتی عضوِ '
        'تیم سرکوب یا یه تیمِ مستقل — و اونم از همون ضربه یا از حذف‌شدن '
        'توسطِ تیمِ رقیب در امان می‌مونه. در طولِ کلِ بازی فقط می‌تونه خودش '
        'رو تعدادِ محدودی نجات بده (پیش‌فرض ۲ بار؛ پیش از شروعِ بازی '
        'قابل‌تغییره).',
    canHeal: true,
  );

  static final List<GameRole> all = [
    valiFaghih,
    foreignMinister,
    suppressor,
    judiciaryChief,
    doctor,
  ];

  static GameRole? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<GameRole> forTeam(String teamId) =>
      all.where((r) => r.teamId == teamId).toList();
}
