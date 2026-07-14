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
  final String imageAsset;
  final NightActionKind nightAction;

  // ---- فیلدهای مخصوص ولی‌فقیه (بعداً برای نقش‌های دیگه هم مشابهش اضافه می‌شه) ----
  final bool alwaysShowsInnocent; // استعلامش همیشه منفیه
  final bool hasNightArmor; // زره در شب
  final bool canSlaughter; // قابلیت سلاخی داره؟

  const GameRole({
    required this.id,
    required this.name,
    required this.teamId,
    required this.description,
    required this.imageAsset,
    this.nightAction = NightActionKind.none,
    this.alwaysShowsInnocent = false,
    this.hasNightArmor = false,
    this.canSlaughter = false,
  });
}

/// کتابخونه‌ی نقش‌های سناریوی سرکوب — نقش‌ها یکی‌یکی این‌جا اضافه می‌شن.
class SarkoobRoles {
  static const valiFaghih = GameRole(
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

  static const List<GameRole> all = [valiFaghih];

  static GameRole? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<GameRole> forTeam(String teamId) =>
      all.where((r) => r.teamId == teamId).toList();
}
