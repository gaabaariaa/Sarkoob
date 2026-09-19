import 'package:flutter/material.dart';

/// یه سناریوی کاملاً مستقل: مجموعه‌ی خودش از تیم‌ها و نقش‌ها. موقعِ
/// شروعِ بازی، گرداننده اول سناریو رو انتخاب می‌کنه؛ از اون به بعد فقط
/// تیم‌ها/نقش‌های همون سناریو قابل‌انتخابن. دو سناریو هیچ تیم/نقشی
/// باهم مشترک ندارن (حتی اگه اسمِ نمایشی شبیه باشه، id ها جدان).
enum GameScenarioSetupMode { sorkoob, mafia }

class GameScenario {
  final String id;
  final GameScenarioSetupMode setupMode;
  final String name;
  final String description;
  final Color color;
  final String emoji;
  final String leaderTeamId;
  final String townTeamId;
  final String independentTeamId;
  final String leaderDefaultRoleId;
  final String townDefaultRoleId;
  final String negotiatorRoleId;
  final String independentLeaderRoleId;

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

  String roleIdFor(String key) => roleIds[key] ?? key;

  const GameScenario({
    required this.id,
    required this.setupMode,
    required this.name,
    required this.description,
    required this.color,
    required this.emoji,
    required this.leaderTeamId,
    required this.townTeamId,
    required this.independentTeamId,
    required this.leaderDefaultRoleId,
    required this.townDefaultRoleId,
    required this.negotiatorRoleId,
    required this.independentLeaderRoleId,
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
  });
}

/// سناریوهای موجودِ اپ.
class SarkoobScenarios {
  static const sorkoob = GameScenario(
    id: 'scenario_sorkoob',
    setupMode: GameScenarioSetupMode.sorkoob,
    name: 'سرکوب',
    description:
        'فضاسازیِ فرهنگی-سیاسیِ ایرانی: تیمِ سرکوبِ حکومتی در برابرِ شهروندان، '
        'با امکانِ یه تیمِ مستقلِ اختیاری (مثلِ موساد). ۲۱ نقشِ کاملاً '
        'پیاده‌سازی‌شده و پرجزئیات.',
    color: Color(0xFFB71C1C),
    emoji: '🕵️',
    leaderTeamId: 'team_sorkoob',
    townTeamId: 'team_citizen',
    independentTeamId: 'team_mossad',
    leaderDefaultRoleId: 'role_suppressor',
    townDefaultRoleId: 'role_gray_citizen',
    negotiatorRoleId: 'role_foreign_minister',
    independentLeaderRoleId: 'role_mossad_leader',
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
    },
  );

  static const mafia = GameScenario(
    id: 'scenario_mafia',
    setupMode: GameScenarioSetupMode.mafia,
    name: 'مافیا',
    description:
        'نسخه‌ی کلاسیکِ بازیِ مافیا: تیمِ مافیا شب‌ها با هم روی یه نفر برای '
        'حذف توافق می‌کنن، در برابرِ اهالیِ شهر که قابلیتِ ویژه‌ای ندارن. '
        'فعلاً یه نسخه‌ی حداقلی؛ مثلِ سرکوب می‌شه نقش‌های بیشتر (دکتر، '
        'کارآگاه و...) رو یکی‌یکی بهش اضافه کرد.',
    color: Color(0xFF37474F),
    emoji: '🎭',
    leaderTeamId: 'team_mafia_gang',
    townTeamId: 'team_mafia_town',
    independentTeamId: 'team_zodiac',
    leaderDefaultRoleId: 'role_simple_mafia',
    townDefaultRoleId: 'role_simple_citizen',
    negotiatorRoleId: 'role_negotiator',
    independentLeaderRoleId: 'role_zodiac',
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
