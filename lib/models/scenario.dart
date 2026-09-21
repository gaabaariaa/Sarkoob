import 'package:flutter/material.dart';

/// یه سناریوی کاملاً مستقل: مجموعه‌ی خودش از تیم‌ها و نقش‌ها. موقعِ
/// شروعِ بازی، گرداننده اول سناریو رو انتخاب می‌کنه؛ از اون به بعد فقط
/// تیم‌ها/نقش‌های همون سناریو قابل‌انتخابن. دو سناریو هیچ تیم/نقشی
/// باهم مشترک ندارن (حتی اگه اسمِ نمایشی شبیه باشه، id ها جدان).
/// قواعدِ شروعِ بازی که به خودِ سناریو تعلق دارند، نه به UI شروع بازی.
///
/// این آبجکت عمداً جزئیاتِ توازن و مقداردهی اولیه‌ی نقش‌ها را نگه می‌دارد
/// تا StartGameScreen مجبور نباشد سناریوها را با if/switch از هم تشخیص بدهد.
class GameScenarioSetupRules {
  final String simpleLeaderRoleId;
  final String simpleTownRoleId;
  final int independentPlayerCount;
  final double? maxLeaderTeamFraction;
  final double? minTownTeamFraction;
  final String? balanceWarning;
  final String slaughterRoleId;
  final String? revolutionaryRoleId;
  final String? warGunRoleId;
  final String? intelRoleId;
  final String? guaranteeRoleId;
  final Set<String> armorRoleIds;

  const GameScenarioSetupRules({
    required this.simpleLeaderRoleId,
    required this.simpleTownRoleId,
    this.independentPlayerCount = 0,
    this.maxLeaderTeamFraction,
    this.minTownTeamFraction,
    this.balanceWarning,
    required this.slaughterRoleId,
    this.revolutionaryRoleId,
    this.warGunRoleId,
    this.intelRoleId,
    this.guaranteeRoleId,
    this.armorRoleIds = const <String>{},
  });
}

class GameScenario {
  final String id;
  final GameScenarioSetupRules setupRules;
  final String name;
  final String description;
  final Color color;
  final String emoji;
  final String leaderTeamId;
  final String townTeamId;
  final String independentTeamId;
  final String leaderRoleId;
  final String leaderDefaultRoleId;
  final String townDefaultRoleId;
  final String negotiatorRoleId;
  final String independentLeaderRoleId;

  /// ترتیب مراحل شب به‌صورت کلیدهای قراردادی؛ Controller فقط آن‌ها را اجرا می‌کند.
  final List<String> nightStepOrder;

  /// نقشی که در این سناریو می‌تواند تیمِ رهبر را برای شبِ بعد غیرفعال کند.
  /// در سناریوهایی که چنین قابلیتی ندارند null است.
  final String? leaderTeamDisableTriggerRoleId;

  /// نقش‌های ساده‌ی پیش‌فرضِ این سناریو؛ موتور نباید از نام/سناریوی خاص
  /// استنتاج کند که چه نقشی «فعال» نیست.
  final Set<String> simpleRoleIds;

  /// برچسب‌های نمایشیِ قابلیت‌هایی که بین سناریوها رفتار مشابه دارند.
  final String leaderLabel;
  final String resistanceTeamLabel;
  final String resistanceGroupLabel;
  final String forbiddenWordLabel;
  final String revolutionaryActionLabel;
  final String independentInvestigationQuestion;
  final String independentInvestigationYes;
  final String independentInvestigationNo;
  final Map<String, String> roleIds;

  /// نقش‌های قابل انتخاب در صفحهٔ Setup، به تفکیک تیم و با حفظ ترتیب UI.
  /// سناریو مالک این کاتالوگ است؛ صفحهٔ شروع نباید بداند کدام نقش‌ها متعلق
  /// به «سرکوب» یا «مافیا» هستند.
  final Map<String, List<String>> setupRoleKeysByTeam;

  String roleIdFor(String key) => roleIds[key] ?? key;

  List<String> setupRoleKeysForTeam(String teamId) =>
      List.unmodifiable(setupRoleKeysByTeam[teamId] ?? const <String>[]);

  List<String> setupRoleIdsForTeam(String teamId) =>
      setupRoleKeysForTeam(teamId).map(roleIdFor).toList(growable: false);

  const GameScenario({
    required this.id,
    required this.setupRules,
    required this.name,
    required this.description,
    required this.color,
    required this.emoji,
    required this.leaderTeamId,
    required this.townTeamId,
    required this.independentTeamId,
    required this.leaderRoleId,
    required this.leaderDefaultRoleId,
    required this.townDefaultRoleId,
    required this.negotiatorRoleId,
    required this.independentLeaderRoleId,
    required this.nightStepOrder,
    this.leaderTeamDisableTriggerRoleId,
    required this.simpleRoleIds,
    required this.leaderLabel,
    required this.resistanceTeamLabel,
    required this.resistanceGroupLabel,
    required this.forbiddenWordLabel,
    required this.revolutionaryActionLabel,
    required this.independentInvestigationQuestion,
    required this.independentInvestigationYes,
    required this.independentInvestigationNo,
    required this.roleIds,
    required this.setupRoleKeysByTeam,
  });
}

/// سناریوهای موجودِ اپ.
class GameScenarios {
  static const sorkoob = GameScenario(
    id: 'scenario_sorkoob',
    setupRules: GameScenarioSetupRules(
      simpleLeaderRoleId: 'role_suppressor',
      simpleTownRoleId: 'role_gray_citizen',
      independentPlayerCount: 1,
      minTownTeamFraction: 2 / 3,
      balanceWarning: 'تعداد تیم مقاومت (شهروند) کمتر از دو‌سومِ کل نفراته؛ تیم مقاومت قدرت کمتری نسبت به بقیه‌ی تیم‌ها داره. می‌خوای همینطوری ادامه بدی؟',
      slaughterRoleId: 'role_vali_faghih',
      revolutionaryRoleId: 'role_revolutionary_fighter',
      warGunRoleId: 'role_rebel',
      intelRoleId: 'role_intelligence_minister',
      guaranteeRoleId: 'role_national_hero',
      armorRoleIds: {'role_vali_faghih'},
    ),
    name: 'سرکوب',
    description:
        'فضاسازیِ فرهنگی-سیاسیِ ایرانی: تیمِ سرکوبِ حکومتی در برابرِ شهروندان، '
        'با امکانِ یه تیمِ مستقلِ اختیاری (مثلِ موساد). ۲۱ نقشِ کاملاً '
        'پیاده‌سازی‌شده و پرجزئیات.',
    color: Color(0xFFB71C1C),
    emoji: '🕵️',
    leaderTeamId: 'team_sorkoob',
    leaderRoleId: 'role_vali_faghih',
    townTeamId: 'team_citizen',
    independentTeamId: 'team_mossad',
    leaderDefaultRoleId: 'role_suppressor',
    townDefaultRoleId: 'role_gray_citizen',
    negotiatorRoleId: 'role_foreign_minister',
    independentLeaderRoleId: 'role_mossad_leader',
    leaderTeamDisableTriggerRoleId: 'role_zhina',
    nightStepOrder: [
      'leaderTeam',
      'doctor',
      'hacker',
      'revolutionary',
      'rebel',
      'rapper',
      'politicalAnalyst',
      'nationalHero',
      'civicActivist',
      'lawyer',
      'independentLeader',
    ],

    simpleRoleIds: {'role_suppressor', 'role_gray_citizen'},
    leaderLabel: 'سرکوب',
    resistanceTeamLabel: 'تیمِ مقاومتِ فعال',
    resistanceGroupLabel: 'مقاومت',
    forbiddenWordLabel: 'کلمه‌ی ممنوع',
    revolutionaryActionLabel: 'اعدامِ انقلابی',
    independentInvestigationQuestion: 'عضوِ یه تیمِ مستقله',
    independentInvestigationYes: 'مستقله',
    independentInvestigationNo: 'مستقل نیست',
    roleIds: {
      'independentLeader': 'role_mossad_leader',
      'rapper': 'role_rapper',
      'hacker': 'role_hacker',
      'politicalAnalyst': 'role_political_analyst',
      'rebel': 'role_rebel',
      'revolutionary': 'role_revolutionary_fighter',
      'nationalHero': 'role_national_hero',
      'civicActivist': 'role_civic_activist',
      'lawyer': 'role_lawyer',
      'judiciary': 'role_judiciary_chief',
      'policeCommander': 'role_police_commander',
      'natasha': 'role_natasha',
      'interrogator': 'role_interrogator',
      'intelligenceMinister': 'role_intelligence_minister',
      'kidnapper': 'role_kidnapper',
      'zhina': 'role_zhina',
      'mistress': 'role_mistress',
      'discloser': 'role_discloser',
      'saboteur': 'role_saboteur',
      'bomber': 'role_bomber',
      'guard': 'role_guard',
      'leaderRole': 'role_vali_faghih',
      'negotiator': 'role_foreign_minister',
      'celebrity': 'role_government_celebrity',
      'mercenary': 'role_mercenary',
      'doctor': 'role_doctor',
    },
    setupRoleKeysByTeam: {
      'team_sorkoob': [
        'leaderRole', 'negotiator', 'judiciary', 'celebrity',
        'interrogator', 'intelligenceMinister', 'policeCommander', 'mercenary',
      ],
      'team_citizen': [
        'doctor', 'hacker', 'revolutionary', 'lawyer', 'zhina', 'rapper',
        'rebel', 'nationalHero', 'civicActivist', 'politicalAnalyst',
      ],
    },
  );

  static const mafia = GameScenario(
    id: 'scenario_mafia',
    setupRules: GameScenarioSetupRules(
      simpleLeaderRoleId: 'role_simple_mafia',
      simpleTownRoleId: 'role_simple_citizen',
      independentPlayerCount: 1,
      maxLeaderTeamFraction: 1 / 3,
      balanceWarning: 'تعدادِ مافیا بیشتر از یک‌سومِ کل نفراته؛ تیمِ مافیا قدرتِ زیادی نسبت به اهالیِ شهر داره. می‌خوای همینطوری ادامه بدی؟',
      slaughterRoleId: 'role_godfather',
      revolutionaryRoleId: 'role_professional',
      warGunRoleId: 'role_gunman',
      intelRoleId: null,
      guaranteeRoleId: 'role_white_beard',
      armorRoleIds: {'role_godfather', 'role_professional'},
    ),
    name: 'مافیا',
    description:
        'نسخه‌ی کلاسیکِ بازیِ مافیا: تیمِ مافیا شب‌ها با هم روی یه نفر برای '
        'حذف توافق می‌کنن، در برابرِ اهالیِ شهر که قابلیتِ ویژه‌ای ندارن. '
        'فعلاً یه نسخه‌ی حداقلی؛ مثلِ سرکوب می‌شه نقش‌های بیشتر (دکتر، '
        'کارآگاه و...) رو یکی‌یکی بهش اضافه کرد.',
    color: Color(0xFF37474F),
    emoji: '🎭',
    leaderTeamId: 'team_mafia_gang',
    leaderRoleId: 'role_godfather',
    townTeamId: 'team_mafia_town',
    independentTeamId: 'team_zodiac',
    leaderDefaultRoleId: 'role_simple_mafia',
    townDefaultRoleId: 'role_simple_citizen',
    negotiatorRoleId: 'role_negotiator',
    independentLeaderRoleId: 'role_zodiac',
    leaderTeamDisableTriggerRoleId: null,
    nightStepOrder: [
      'leaderTeam',
      'doctor',
      'hacker',
      'revolutionary',
      'rebel',
      'rapper',
      'politicalAnalyst',
      'nationalHero',
      'civicActivist',
      'lawyer',
      'independentLeader',
    ],

    simpleRoleIds: {'role_simple_mafia', 'role_simple_citizen'},
    leaderLabel: 'مافیا',
    resistanceTeamLabel: 'تیمِ اوشن',
    resistanceGroupLabel: 'تیمِ اوشن',
    forbiddenWordLabel: 'کلمه‌ی طلسم‌شده',
    revolutionaryActionLabel: 'حذفِ حرفه‌ای',
    independentInvestigationQuestion: 'زودیاکه',
    independentInvestigationYes: 'زودیاکه',
    independentInvestigationNo: 'زودیاک نیست',
    roleIds: {
      'independentLeader': 'role_zodiac',
      'rapper': 'role_ocean',
      'hacker': 'role_detective',
      'politicalAnalyst': 'role_sherlock',
      'rebel': 'role_gunman',
      'revolutionary': 'role_professional',
      'nationalHero': 'role_white_beard',
      'civicActivist': 'role_leader',
      'lawyer': 'role_konstantin',
      'judiciary': 'role_enchanter',
      'policeCommander': 'role_kidnapper',
      'leaderRole': 'role_godfather',
      'warGun': 'role_gunman',
      'guarantee': 'role_white_beard',
      'doctor': 'role_mafia_doctor',
      'spy': 'role_spy',
      'terrorist': 'role_terrorist',
      'bomber': 'role_bomber',
      'mistress': 'role_mistress',
      'natasha': 'role_natasha',
      'saboteur': 'role_saboteur',
      'guard': 'role_guard',
      'discloser': 'role_discloser',
    },
    setupRoleKeysByTeam: {
      'team_mafia_gang': [
        'leaderRole', 'negotiator', 'judiciary', 'spy', 'policeCommander',
        'terrorist', 'bomber', 'mistress', 'natasha', 'saboteur',
      ],
      'team_mafia_town': [
        'doctor', 'hacker', 'revolutionary', 'lawyer', 'rapper', 'warGun',
        'civicActivist', 'politicalAnalyst', 'guard', 'discloser', 'guarantee',
      ],
    },
  );

  /// سناریوی پیش‌فرض فقط برای UX است؛ منطق بازی نباید به آن fallback کند.
  static const GameScenario defaultScenario = sorkoob;

  static const List<GameScenario> all = [sorkoob, mafia];

  static GameScenario? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
