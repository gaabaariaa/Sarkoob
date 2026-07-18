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

  /// بعضی نقش‌ها (مثل «سرکوبگر»ی که از مذاکره به‌وجود میاد) کارت اختصاصی
  /// ندارن؛ برای همین این فیلد nullable ـه.
  final String? imageAsset;

  final NightActionKind nightAction;

  // ---- فیلدهای مخصوص ولی‌فقیه ----
  final bool alwaysShowsInnocent; // استعلامش همیشه منفیه
  final bool hasNightArmor; // زره در شب
  final bool canSlaughter; // قابلیت سلاخی داره؟

  // ---- فیلدِ مخصوص وزیر امور خارجه ----
  final bool canNegotiate; // قابلیت اغفال/مذاکره داره؟

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
  });
}

/// کتابخونه‌ی نقش‌های سناریوی سرکوب — نقش‌ها یکی‌یکی این‌جا اضافه می‌شن.
class SarkoobRoles {
  static final valiFaghih = GameRole(
    id: 'role_vali_faghih',
    name: 'ولی فقیه',
    teamId: SarkoobTeams.suppression.id,
    imageAsset: 'assets/roles/vali_faghih.jpg',
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
    imageAsset: 'assets/roles/zarif.jpg',
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

  static final List<GameRole> all = [valiFaghih, foreignMinister, suppressor];

  static GameRole? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<GameRole> forTeam(String teamId) =>
      all.where((r) => r.teamId == teamId).toList();
}
