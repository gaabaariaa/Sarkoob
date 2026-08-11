import 'package:flutter/material.dart';

/// یه تیم توی یه سناریو (مثلاً «سرکوب» یا «شهروند»).
class GameTeam {
  final String id;
  final String name;
  final Color color;
  final String description;

  const GameTeam({
    required this.id,
    required this.name,
    required this.color,
    this.description = '',
  });
}

/// تیم‌های سناریوی «سرکوب».
class SarkoobTeams {
  static const suppression = GameTeam(
    id: 'team_sorkoob',
    name: 'سرکوب',
    color: Color(0xFFB71C1C),
    description: 'نیروهای سرکوب‌گر حکومتی؛ هدفشون حذف مخفیانه‌ی مخالفان.',
  );

  static const citizen = GameTeam(
    id: 'team_citizen',
    name: 'شهروند',
    color: Color(0xFF1976D2),
    description: 'مردم عادی و فعالان مدنی؛ هدفشون شناسایی و حذف سرکوب‌گرهاست.',
  );

  static const mossad = GameTeam(
    id: 'team_mossad',
    name: 'موساد',
    color: Color(0xFF546E7A),
    description: 'عامل نفوذی خارجی با اهداف و اقدامات مستقل خودش.',
  );

  static const mek = GameTeam(
    id: 'team_mek',
    name: 'مجاهدین خلق',
    color: Color(0xFFF9A825),
    description: 'گروه اپوزیسیون مسلح با اهداف و اقدامات مستقل خودش.',
  );

  static const List<GameTeam> all = [suppression, citizen, mossad, mek];

  /// تیم‌هایی که الان واقعاً قابل‌انتخابن — فعلاً مجاهدین خلق از سایدِ
  /// مستقل حذف شده (شاید بعداً یه تیمِ دیگه جاش بیاد). `all` رو دست‌نخورده
  /// نگه داشتیم که `byId` برای بازی‌های قدیمی/تاریخچه‌ای که شاید هنوز
  /// `team_mek` داشته باشن هم درست کار کنه.
  static const List<GameTeam> selectable = [suppression, citizen, mossad];

  static GameTeam? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
