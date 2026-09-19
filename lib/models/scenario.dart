import 'package:flutter/material.dart';

import 'role.dart';
import 'team.dart';

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
    leaderTeamId: SarkoobTeams.suppression.id,
    townTeamId: SarkoobTeams.citizen.id,
    independentTeamId: SarkoobTeams.mossad.id,
    leaderDefaultRoleId: SarkoobRoles.suppressor.id,
    townDefaultRoleId: SarkoobRoles.grayCitizen.id,
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
    leaderTeamId: SarkoobTeams.mafiaGang.id,
    townTeamId: SarkoobTeams.mafiaTown.id,
    independentTeamId: SarkoobTeams.zodiac.id,
    leaderDefaultRoleId: SarkoobRoles.simpleMafia.id,
    townDefaultRoleId: SarkoobRoles.simpleCitizen.id,
  );

  static const List<GameScenario> all = [sorkoob, mafia];

  static GameScenario? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
