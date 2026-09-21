import 'role.dart';
import 'scenario.dart';
import 'team.dart';

/// معیارِ «موفقیتِ اختصاصیِ» یه نقش: کدوم برچسب‌هایِ ScoreEvent.mechanism
/// (به‌صورتِ substring) شمرده بشن، و واحدِ نمایشیش چیه.
class RoleSuccessMetric {
  final List<String> mechanisms;
  final String unitLabel; // مثلاً «سیوِ صحیح»
  const RoleSuccessMetric(this.mechanisms, this.unitLabel);
}

/// فقط نقش‌هایی که یه مکانیزمِ امتیازیِ روشن دارن این‌جان (طبقِ
/// role_scoring_info.dart)؛ نقش‌هایِ بدونِ قابلیتِ اختصاصی (سرکوبگر،
/// ژینا، پرستویِ نظام، شهروندِ‌خاکستری/ساده، مافیایِ‌ساده، معشوقه) عمداً
/// حذف شدن — معیارِ معناداری برایِ «بهترینِ فلان نقش»شون وجود نداره.
final Map<String, RoleSuccessMetric> roleSuccessMetrics = {
  // ---------------- سرکوب ----------------
  GameRoles.valiFaghih.id: RoleSuccessMetric(['شاتِ رهبر', 'سلاخیِ رهبر'], 'حذفِ موفق'),
  GameRoles.foreignMinister.id: RoleSuccessMetric(['مذاکره‌ی موفق'], 'مذاکره‌ی موفق'),
  GameRoles.judiciaryChief.id: RoleSuccessMetric(['حکمِ کلمه‌ی ممنوع'], 'حکمِ درست'),
  GameRoles.doctor.id: RoleSuccessMetric(['نجاتِ شبانه‌ی دکتر'], 'سیوِ صحیح'),
  GameRoles.hacker.id: RoleSuccessMetric(['استعلامِ هکر/کارآگاه'], 'استعلامِ درست'),
  GameRoles.revolutionaryFighter.id:
      RoleSuccessMetric(['اعدامِ انقلابی', 'سلاخیِ مبارزِ انقلابی/حرفه‌ای'], 'حذفِ موفق'),
  GameRoles.lawyer.id: RoleSuccessMetric(['احیایِ وکیل/کنستانتین'], 'احیایِ موفق'),
  GameRoles.rapper.id: RoleSuccessMetric(['جذبِ مقاومتِ موفق'], 'جذبِ موفق'),
  GameRoles.rebel.id: RoleSuccessMetric(['توزیعِ اسلحه‌ی جنگی'], 'توزیعِ درست'),
  GameRoles.interrogator.id: RoleSuccessMetric(['بازجویی/جاسوسی'], 'بازجوییِ درست'),
  GameRoles.intelligenceMinister.id: RoleSuccessMetric(['سؤالِ اطلاعاتی'], 'سؤالِ مفید'),
  GameRoles.policeCommander.id: RoleSuccessMetric(['بازداشتِ شبانه'], 'بازداشتِ مؤثر'),
  GameRoles.mercenary.id: RoleSuccessMetric(['ترورِ مزدور/تروریست'], 'ترورِ موفق'),
  GameRoles.nationalHero.id: RoleSuccessMetric(['تضمینِ قهرمانِ ملی/ریش‌سفید'], 'تضمینِ مؤثر'),
  GameRoles.mossadLeader.id:
      RoleSuccessMetric(['ترورِ رهبرِ تیمِ مستقل', 'شاتِ سریِ رهبرِ تیمِ مستقل'], 'حذفِ موفق'),
  GameRoles.civicActivist.id:
      RoleSuccessMetric(['تحریکِ رفراندوم', 'انتخابِ اخراجِ رهبرِ جامعه'], 'تصمیمِ درست'),
  GameRoles.politicalAnalyst.id:
      RoleSuccessMetric(['استعلامِ تحلیلگرِ سیاسی/شرلوک'], 'شناساییِ درست'),

  // ---------------- مافیا ----------------
  GameRoles.godfather.id: RoleSuccessMetric(['شاتِ رهبر', 'سلاخیِ رهبر'], 'حذفِ موفق'),
  GameRoles.negotiator.id: RoleSuccessMetric(['مذاکره‌ی موفق'], 'مذاکره‌ی موفق'),
  GameRoles.enchanter.id: RoleSuccessMetric(['حکمِ کلمه‌ی ممنوع'], 'حکمِ درست'),
  GameRoles.mafiaDoctor.id: RoleSuccessMetric(['نجاتِ شبانه‌ی دکتر'], 'سیوِ صحیح'),
  GameRoles.detective.id: RoleSuccessMetric(['استعلامِ هکر/کارآگاه'], 'استعلامِ درست'),
  GameRoles.professional.id:
      RoleSuccessMetric(['اعدامِ انقلابی', 'سلاخیِ مبارزِ انقلابی/حرفه‌ای'], 'حذفِ موفق'),
  GameRoles.konstantin.id: RoleSuccessMetric(['احیایِ وکیل/کنستانتین'], 'احیایِ موفق'),
  GameRoles.ocean.id: RoleSuccessMetric(['جذبِ مقاومتِ موفق'], 'جذبِ موفق'),
  GameRoles.spy.id: RoleSuccessMetric(['بازجویی/جاسوسی'], 'بازجوییِ درست'),
  GameRoles.gunman.id: RoleSuccessMetric(['توزیعِ اسلحه‌ی جنگی'], 'توزیعِ درست'),
  GameRoles.kidnapper.id: RoleSuccessMetric(['بازداشتِ شبانه'], 'بازداشتِ مؤثر'),
  GameRoles.terrorist.id: RoleSuccessMetric(['ترورِ مزدور/تروریست'], 'ترورِ موفق'),
  GameRoles.zodiacRole.id:
      RoleSuccessMetric(['ترورِ رهبرِ تیمِ مستقل', 'شاتِ سریِ رهبرِ تیمِ مستقل'], 'حذفِ موفق'),
  GameRoles.leader.id:
      RoleSuccessMetric(['تحریکِ رفراندوم', 'انتخابِ اخراجِ رهبرِ جامعه'], 'تصمیمِ درست'),
  GameRoles.sherlock.id: RoleSuccessMetric(['استعلامِ تحلیلگرِ سیاسی/شرلوک'], 'شناساییِ درست'),
  GameRoles.bomber.id: RoleSuccessMetric(['بمب‌گذاری'], 'انفجارِ موفق'),
  GameRoles.guard.id: RoleSuccessMetric(['فداکاریِ محافظ'], 'فداکاری'),
  GameRoles.natasha.id: RoleSuccessMetric(['ساکت‌کردنِ ناتاشا'], 'سکوتِ مؤثر'),
  GameRoles.saboteur.id: RoleSuccessMetric(['خرابکاریِ موفق'], 'خرابکاریِ موفق'),
  GameRoles.discloser.id: RoleSuccessMetric(['افشایِ عمومیِ تیم'], 'افشایِ مفید'),
  GameRoles.whiteBeard.id: RoleSuccessMetric(['تضمینِ قهرمانِ ملی/ریش‌سفید'], 'تضمینِ مؤثر'),
};

/// کاتالوگِ معیارهایِ امتیازیِ قابل‌استفاده در یک سناریو.
/// رجیستریِ اصلی عمداً بر اساس roleId نگه داشته می‌شود تا تاریخچه‌ی بازی‌های
/// مختلف بتواند همان داده را بخواند؛ این accessor فقط نقش‌های همان سناریو را
/// در اختیار لایه‌های UI/آمار می‌گذارد.
Map<String, RoleSuccessMetric> roleSuccessMetricsForScenario(GameScenario scenario) {
  final teamIds = GameTeams.forScenario(scenario.id).map((t) => t.id).toSet();
  return Map.unmodifiable({
    for (final entry in roleSuccessMetrics.entries)
      if (GameRoles.byId(entry.key) != null && teamIds.contains(GameRoles.byId(entry.key)!.teamId)) entry.key: entry.value,
  });
}
