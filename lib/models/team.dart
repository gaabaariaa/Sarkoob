import 'package:flutter/material.dart';
import 'scenario.dart';

/// یه تیم توی یه سناریوی مشخص — هر تیم دقیقاً به یه سناریو تعلق داره
/// (`scenarioId`)، و دو سناریو هیچ تیمی باهم مشترک ندارن.
class GameTeam {
  final String id;
  final String name;
  final Color color;
  final String description;
  final String scenarioId;

  const GameTeam({
    required this.id,
    required this.name,
    required this.color,
    required this.scenarioId,
    this.description = '',
  });
}

/// همه‌ی تیم‌های همه‌ی سناریوها. چون تعریفشون به فیلدِ یه شیءِ `const`ِ
/// دیگه (`SarkoobScenarios.x.id`) نیاز داره، اینجا هم مثلِ نقش‌ها از
/// `final` استفاده می‌کنیم، نه `const`.
class SarkoobTeams {
  // ---------- سناریوی «سرکوب» ----------
  static final suppression = GameTeam(
    id: 'team_sorkoob',
    name: 'سرکوب',
    color: const Color(0xFFB71C1C),
    scenarioId: SarkoobScenarios.sorkoob.id,
    description: 'نیروهای سرکوب‌گر حکومتی؛ هدفشون حذف مخفیانه‌ی مخالفان.',
  );

  static final citizen = GameTeam(
    id: 'team_citizen',
    name: 'شهروند',
    color: const Color(0xFF1976D2),
    scenarioId: SarkoobScenarios.sorkoob.id,
    description: 'مردم عادی و فعالان مدنی؛ هدفشون شناسایی و حذف سرکوب‌گرهاست.',
  );

  static final mossad = GameTeam(
    id: 'team_mossad',
    name: 'موساد',
    color: const Color(0xFF546E7A),
    scenarioId: SarkoobScenarios.sorkoob.id,
    description: 'عامل نفوذی خارجی با اهداف و اقدامات مستقل خودش.',
  );

  static final mek = GameTeam(
    id: 'team_mek',
    name: 'مجاهدین خلق',
    color: const Color(0xFFF9A825),
    scenarioId: SarkoobScenarios.sorkoob.id,
    description: 'گروه اپوزیسیون مسلح با اهداف و اقدامات مستقل خودش.',
  );

  // ---------- سناریوی «مافیا» ----------
  /// شب‌ها با هم بیدار می‌شن، همدیگه رو می‌شناسن، و روی یه نفر برای حذف
  /// توافق می‌کنن. بینِ اعضای این تیم فرقی نیست — همه یه نقشِ یکسان دارن.
  static final mafiaGang = GameTeam(
    id: 'team_mafia_gang',
    name: 'مافیا',
    color: const Color(0xFF212121),
    scenarioId: SarkoobScenarios.mafia.id,
    description: 'شب‌ها با هم بیدار می‌شن و روی یه نفر برای حذف توافق می‌کنن.',
  );

  /// اهالیِ شهر — بدونِ قابلیتِ ویژه، فقط با رأی و تحلیل دنبالِ مافیا
  /// می‌گردن.
  static final mafiaTown = GameTeam(
    id: 'team_mafia_town',
    name: 'شهروند',
    color: const Color(0xFF1976D2),
    scenarioId: SarkoobScenarios.mafia.id,
    description: 'بدونِ قابلیتِ ویژه؛ فقط با رأی و تحلیل دنبالِ مافیا می‌گردن.',
  );

  /// تیمِ مستقلِ سناریوی مافیا — معادلِ موساد تو سناریوی سرکوب. همیشه
  /// دقیقاً ۱ نفره (خودِ زودیاک).
  static final zodiac = GameTeam(
    id: 'team_zodiac',
    name: 'زودیاک',
    color: const Color(0xFF4A148C),
    scenarioId: SarkoobScenarios.mafia.id,
    description: 'مأمورِ رمزآلودِ مستقل، با اهداف و اقداماتِ مستقلِ خودش.',
  );

  static final List<GameTeam> all = [
    suppression,
    citizen,
    mossad,
    mek,
    mafiaGang,
    mafiaTown,
    zodiac,
  ];

  /// تیم‌هایی که الان واقعاً قابل‌انتخابن — فعلاً مجاهدین خلق از سایدِ
  /// مستقلِ سرکوب حذف شده (شاید بعداً یه تیمِ دیگه جاش بیاد). `all` رو
  /// دست‌نخورده نگه داشتیم که `byId` برای بازی‌های قدیمی/تاریخچه‌ای که
  /// شاید هنوز `team_mek` داشته باشن هم درست کار کنه.
  static final List<GameTeam> selectable = [
    suppression,
    citizen,
    mossad,
    mafiaGang,
    mafiaTown,
    zodiac,
  ];

  static GameTeam? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// همه‌ی تیم‌های یه سناریوی خاص (چه قابل‌انتخاب چه نه — مثلِ `all`).
  static List<GameTeam> forScenario(String scenarioId) =>
      all.where((t) => t.scenarioId == scenarioId).toList();

  /// تیم‌های قابل‌انتخابِ یه سناریوی خاص (چه تو شروعِ بازی چه تو قوانین).
  static List<GameTeam> selectableForScenario(String scenarioId) =>
      selectable.where((t) => t.scenarioId == scenarioId).toList();
}
