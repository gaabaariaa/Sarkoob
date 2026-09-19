import 'package:flutter/material.dart';

/// یه سناریوی کاملاً مستقل: مجموعه‌ی خودش از تیم‌ها و نقش‌ها. موقعِ
/// شروعِ بازی، گرداننده اول سناریو رو انتخاب می‌کنه؛ از اون به بعد فقط
/// تیم‌ها/نقش‌های همون سناریو قابل‌انتخابن. دو سناریو هیچ تیم/نقشی
/// باهم مشترک ندارن (حتی اگه اسمِ نمایشی شبیه باشه، id ها جدان).
class GameScenario {
  final String id;
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

  const GameScenario({
    required this.id,
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
  });
}

/// سناریوهای موجودِ اپ.
class SarkoobScenarios {
  static const sorkoob = GameScenario(
    id: 'scenario_sorkoob',
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
  );

  static const mafia = GameScenario(
    id: 'scenario_mafia',
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
  );

  static const List<GameScenario> all = [sorkoob, mafia];

  static GameScenario? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
