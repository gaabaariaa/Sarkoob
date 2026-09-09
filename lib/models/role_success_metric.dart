import 'role.dart';

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
  SarkoobRoles.valiFaghih.id: RoleSuccessMetric(['شاتِ رهبر', 'سلاخیِ رهبر'], 'حذفِ موفق'),
  SarkoobRoles.foreignMinister.id: RoleSuccessMetric(['مذاکره‌ی موفق'], 'مذاکره‌ی موفق'),
  SarkoobRoles.judiciaryChief.id: RoleSuccessMetric(['حکمِ کلمه‌ی ممنوع'], 'حکمِ درست'),
  SarkoobRoles.doctor.id: RoleSuccessMetric(['نجاتِ شبانه‌ی دکتر'], 'سیوِ صحیح'),
  SarkoobRoles.hacker.id: RoleSuccessMetric(['استعلامِ هکر/کارآگاه'], 'استعلامِ درست'),
  SarkoobRoles.revolutionaryFighter.id:
      RoleSuccessMetric(['اعدامِ انقلابی', 'سلاخیِ مبارزِ انقلابی/حرفه‌ای'], 'حذفِ موفق'),
  SarkoobRoles.lawyer.id: RoleSuccessMetric(['احیایِ وکیل/کنستانتین'], 'احیایِ موفق'),
  SarkoobRoles.rapper.id: RoleSuccessMetric(['جذبِ مقاومتِ موفق'], 'جذبِ موفق'),
  SarkoobRoles.rebel.id: RoleSuccessMetric(['توزیعِ اسلحه‌ی جنگی'], 'توزیعِ درست'),
  SarkoobRoles.interrogator.id: RoleSuccessMetric(['بازجویی/جاسوسی'], 'بازجوییِ درست'),
  SarkoobRoles.intelligenceMinister.id: RoleSuccessMetric(['سؤالِ اطلاعاتی'], 'سؤالِ مفید'),
  SarkoobRoles.policeCommander.id: RoleSuccessMetric(['بازداشتِ شبانه'], 'بازداشتِ مؤثر'),
  SarkoobRoles.mercenary.id: RoleSuccessMetric(['ترورِ مزدور/تروریست'], 'ترورِ موفق'),
  SarkoobRoles.nationalHero.id: RoleSuccessMetric(['تضمینِ قهرمانِ ملی/ریش‌سفید'], 'تضمینِ مؤثر'),
  SarkoobRoles.mossadLeader.id:
      RoleSuccessMetric(['ترورِ رهبرِ تیمِ مستقل', 'شاتِ سریِ رهبرِ تیمِ مستقل'], 'حذفِ موفق'),
  SarkoobRoles.civicActivist.id:
      RoleSuccessMetric(['تحریکِ رفراندوم', 'انتخابِ اخراجِ رهبرِ جامعه'], 'تصمیمِ درست'),
  SarkoobRoles.politicalAnalyst.id:
      RoleSuccessMetric(['استعلامِ تحلیلگرِ سیاسی/شرلوک'], 'شناساییِ درست'),

  // ---------------- مافیا ----------------
  SarkoobRoles.godfather.id: RoleSuccessMetric(['شاتِ رهبر', 'سلاخیِ رهبر'], 'حذفِ موفق'),
  SarkoobRoles.negotiator.id: RoleSuccessMetric(['مذاکره‌ی موفق'], 'مذاکره‌ی موفق'),
  SarkoobRoles.enchanter.id: RoleSuccessMetric(['حکمِ کلمه‌ی ممنوع'], 'حکمِ درست'),
  SarkoobRoles.mafiaDoctor.id: RoleSuccessMetric(['نجاتِ شبانه‌ی دکتر'], 'سیوِ صحیح'),
  SarkoobRoles.detective.id: RoleSuccessMetric(['استعلامِ هکر/کارآگاه'], 'استعلامِ درست'),
  SarkoobRoles.professional.id:
      RoleSuccessMetric(['اعدامِ انقلابی', 'سلاخیِ مبارزِ انقلابی/حرفه‌ای'], 'حذفِ موفق'),
  SarkoobRoles.konstantin.id: RoleSuccessMetric(['احیایِ وکیل/کنستانتین'], 'احیایِ موفق'),
  SarkoobRoles.ocean.id: RoleSuccessMetric(['جذبِ مقاومتِ موفق'], 'جذبِ موفق'),
  SarkoobRoles.spy.id: RoleSuccessMetric(['بازجویی/جاسوسی'], 'بازجوییِ درست'),
  SarkoobRoles.gunman.id: RoleSuccessMetric(['توزیعِ اسلحه‌ی جنگی'], 'توزیعِ درست'),
  SarkoobRoles.kidnapper.id: RoleSuccessMetric(['بازداشتِ شبانه'], 'بازداشتِ مؤثر'),
  SarkoobRoles.terrorist.id: RoleSuccessMetric(['ترورِ مزدور/تروریست'], 'ترورِ موفق'),
  SarkoobRoles.zodiacRole.id:
      RoleSuccessMetric(['ترورِ رهبرِ تیمِ مستقل', 'شاتِ سریِ رهبرِ تیمِ مستقل'], 'حذفِ موفق'),
  SarkoobRoles.leader.id:
      RoleSuccessMetric(['تحریکِ رفراندوم', 'انتخابِ اخراجِ رهبرِ جامعه'], 'تصمیمِ درست'),
  SarkoobRoles.sherlock.id: RoleSuccessMetric(['استعلامِ تحلیلگرِ سیاسی/شرلوک'], 'شناساییِ درست'),
  SarkoobRoles.bomber.id: RoleSuccessMetric(['بمب‌گذاری'], 'انفجارِ موفق'),
  SarkoobRoles.guard.id: RoleSuccessMetric(['فداکاریِ محافظ'], 'فداکاری'),
  SarkoobRoles.natasha.id: RoleSuccessMetric(['ساکت‌کردنِ ناتاشا'], 'سکوتِ مؤثر'),
  SarkoobRoles.saboteur.id: RoleSuccessMetric(['خرابکاریِ موفق'], 'خرابکاریِ موفق'),
  SarkoobRoles.discloser.id: RoleSuccessMetric(['افشایِ عمومیِ تیم'], 'افشایِ مفید'),
  SarkoobRoles.whiteBeard.id: RoleSuccessMetric(['تضمینِ قهرمانِ ملی/ریش‌سفید'], 'تضمینِ مؤثر'),
};
