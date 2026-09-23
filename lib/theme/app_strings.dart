
import 'app_language.dart';

class AppStrings {
  static String t(String key) {
    if (AppLanguageController.current.value == AppLanguage.persian) return _fa[key] ?? key;
    return _en[key] ?? key;
  }

  static const _fa = <String, String>{
    'گرداننده، وضعیت و زمان را از این پنل کنترل می‌کند.':'گرداننده، وضعیت و زمان را از این پنل کنترل می‌کند.',
    'صحبتت را کامل کن؛ بعد از پایان دفاع، نوبت نفر بعدی می‌رسد.':'صحبتت را کامل کن؛ بعد از پایان دفاع، نوبت نفر بعدی می‌رسد.',
    'هر بازیکن فرصت دفاع از خودش را دارد.':'هر بازیکن فرصت دفاع از خودش را دارد.',
    'روستر و تاریخچه‌ی بازی‌ها را در یک فایل ذخیره کن تا بتوانی به گوشی دیگر منتقل یا از فایل قبلی بازیابی کنی.':'روستر و تاریخچه‌ی بازی‌ها را در یک فایل ذخیره کن تا بتوانی به گوشی دیگر منتقل یا از فایل قبلی بازیابی کنی.',
    'هیچ موزیکی انتخاب نشده':'هیچ موزیکی انتخاب نشده',
    'فایل خونده نشد یا خرابه':'فایل خونده نشد یا خرابه',
    'بک‌آپ ذخیره شد.':'بک‌آپ ذخیره شد.',
    'ذخیره‌ی فایلِ بک‌آپ':'ذخیره‌ی فایلِ بک‌آپ',
    'نسخه پشتیبان اطلاعات':'نسخه پشتیبان اطلاعات',
    'جایگزین کن':'جایگزین کن',
    'روستر و تاریخچه‌ی فعلی پاک می‌شن و با فایل جایگزین می‌شن.':'روستر و تاریخچه‌ی فعلی پاک می‌شن و با فایل جایگزین می‌شن.',
    'مطمئنی؟':'مطمئنی؟',
    'جایگزینیِ کامل':'جایگزینیِ کامل',
    'افزودن به داده‌ی فعلی':'افزودن به داده‌ی فعلی',
    'داده‌های فایل به داده‌های فعلی اضافه بشن یا کاملاً جایگزین بشن؟':'داده‌های فایل به داده‌های فعلی اضافه بشن یا کاملاً جایگزین بشن؟',
    'وارد کردنِ بک‌آپ':'وارد کردنِ بک‌آپ',
    'انتقال و بازیابی اطلاعات بازی':'انتقال و بازیابی اطلاعات بازی',
    'بک‌آپ و بازیابی':'بک‌آپ و بازیابی',
    'حذف':'حذف',
    'بعدی':'بعدی',
    'توقفِ پخشِ آزمایشی':'توقفِ پخشِ آزمایشی',
    'پخشِ آزمایشی':'پخشِ آزمایشی',
    'انتخابِ موزیک':'انتخابِ موزیک',
    'موسیقی خودکار فازهای شب و خواب نیمروزی':'موسیقی خودکار فازهای شب و خواب نیمروزی',
    'موزیک شب':'موزیک شب',
    'تیره با حال‌وهوای پرتنش':'تیره با حال‌وهوای پرتنش',
    'قرمز سینمایی':'قرمز سینمایی',
    'سرد، تاریک و مدرن':'سرد، تاریک و مدرن',
    'نیمه‌شب':'نیمه‌شب',
    'تم اصلی دست خدا':'تم اصلی دست خدا',
    'طلایی سلطنتی':'طلایی سلطنتی',
    'زبان رابط کاربری برنامه را انتخاب کن':'زبان رابط کاربری برنامه را انتخاب کن',
    'تنظیمات زبان':'تنظیمات زبان',
    'شخصی‌سازی ظاهر میز بازی':'شخصی‌سازی ظاهر میز بازی',
    'ظاهر برنامه':'ظاهر برنامه',
    'دست خدا':'دست خدا','میز بازی':'میز بازی','همه‌چیز برای اجرای یک شب پرتنش آماده است.':'همه‌چیز برای اجرای یک شب پرتنش آماده است.',
    'نقش مخفی':'نقش مخفی','چند سناریو':'چند سناریو','شروع بازی':'شروع بازی','بازیکنان را انتخاب کن و سناریو را مشخص کن':'بازیکنان را انتخاب کن و سناریو را مشخص کن',
    'مدیریت بازی':'مدیریت بازی','بازیکنان':'بازیکنان','لیست و نقش‌ها':'لیست و نقش‌ها','آمار':'آمار','نتایج و عملکرد':'نتایج و عملکرد','تاریخچه':'تاریخچه','بازی‌های قبلی':'بازی‌های قبلی',
    'سناریوها':'سناریوها','قوانین و سناریوهای بازی':'قوانین و سناریوهای بازی','تنظیمات':'تنظیمات','ظاهر، تم و صدای بازی':'ظاهر، تم و صدای بازی',
    'انتخاب بازیکنان':'انتخاب بازیکنان','لغو همه':'لغو همه','انتخاب همه':'انتخاب همه','تأیید':'تأیید','افزودن':'افزودن','افزودن بازیکن':'افزودن بازیکن',
    'اسمِ بازیکنِ جدید':'اسمِ بازیکنِ جدید','هنوز کسی تو لیست نیست.':'هنوز کسی تو لیست نیست.','انصراف':'انصراف','ذخیره':'ذخیره','ویرایشِ اسم':'ویرایشِ اسم',
    'بازیابی':'بازیابی','خروجی گرفتن':'خروجی گرفتن','تاریخچه بازی‌ها':'تاریخچه بازی‌ها','آمار و عملکرد':'آمار و عملکرد','قوانین و نقش‌ها':'قوانین و نقش‌ها',
    'نمایش نقش‌ها':'نمایش نقش‌ها','انتخابِ همه':'انتخابِ همه','فاز دفاع':'فاز دفاع','نوبت دفاع':'نوبت دفاع','پایان دفاع و نفر بعدی':'پایان دفاع و نفر بعدی',
    'نوبتِ':'نوبتِ','در حال صحبت':'در حال صحبت','چالش فعال':'چالش فعال','نفر بعدی':'نفر بعدی','پایان چالش':'پایان چالش','انتخاب چالش':'انتخاب چالش',
    'کنترل میز بازی':'کنترل میز بازی','زمانِ صحبت':'زمانِ صحبت','تایمر متوقف است':'تایمر متوقف است','مکث':'مکث','پخش':'پخش','توقف':'توقف',
  };
  static const _en = <String, String>{
    'گرداننده، وضعیت و زمان را از این پنل کنترل می‌کند.':'The moderator controls the status and timing from this panel.',
    'صحبتت را کامل کن؛ بعد از پایان دفاع، نوبت نفر بعدی می‌رسد.':'Finish your defense; then it is the next player’s turn.',
    'هر بازیکن فرصت دفاع از خودش را دارد.':'Each player gets a chance to defend themselves.',
    'روستر و تاریخچه‌ی بازی‌ها را در یک فایل ذخیره کن تا بتوانی به گوشی دیگر منتقل یا از فایل قبلی بازیابی کنی.':'Save your roster and game history in one file to transfer or restore them later.',
    'هیچ موزیکی انتخاب نشده':'No music selected',
    'فایل خونده نشد یا خرابه':'The file could not be read or is invalid',
    'بک‌آپ ذخیره شد.':'Backup saved.',
    'ذخیره‌ی فایلِ بک‌آپ':'Save backup file',
    'نسخه پشتیبان اطلاعات':'Data backup',
    'جایگزین کن':'Replace',
    'روستر و تاریخچه‌ی فعلی پاک می‌شن و با فایل جایگزین می‌شن.':'The current roster and history will be replaced by the file.',
    'مطمئنی؟':'Are you sure?',
    'جایگزینیِ کامل':'Replace all',
    'افزودن به داده‌ی فعلی':'Add to current data',
    'داده‌های فایل به داده‌های فعلی اضافه بشن یا کاملاً جایگزین بشن؟':'Add the file data to current data or replace it completely?',
    'وارد کردنِ بک‌آپ':'Import Backup',
    'انتقال و بازیابی اطلاعات بازی':'Transfer and restore game data',
    'بک‌آپ و بازیابی':'Backup & Restore',
    'حذف':'Delete',
    'بعدی':'Next',
    'توقفِ پخشِ آزمایشی':'Stop Preview',
    'پخشِ آزمایشی':'Preview',
    'انتخابِ موزیک':'Choose Music',
    'موسیقی خودکار فازهای شب و خواب نیمروزی':'Automatic music for night phases and nap',
    'موزیک شب':'Night Music',
    'تیره با حال‌وهوای پرتنش':'Dark and intense',
    'قرمز سینمایی':'Cinematic Red',
    'سرد، تاریک و مدرن':'Cool, dark & modern',
    'نیمه‌شب':'Midnight',
    'تم اصلی دست خدا':'Hand of God default theme',
    'طلایی سلطنتی':'Royal Gold',
    'زبان رابط کاربری برنامه را انتخاب کن':'Choose the app interface language',
    'تنظیمات زبان':'Language Settings',
    'شخصی‌سازی ظاهر میز بازی':'Customize the game table appearance',
    'ظاهر برنامه':'Appearance',
    'دست خدا':'Hand of God','میز بازی':'Game Table','همه‌چیز برای اجرای یک شب پرتنش آماده است.':'Everything is ready for an intense night.',
    'نقش مخفی':'Hidden Role','چند سناریو':'Multiple Scenarios','شروع بازی':'Start Game','بازیکنان را انتخاب کن و سناریو را مشخص کن':'Choose players and select a scenario',
    'مدیریت بازی':'Game Management','بازیکنان':'Players','لیست و نقش‌ها':'Roster & Roles','آمار':'Stats','نتایج و عملکرد':'Results & Performance','تاریخچه':'History','بازی‌های قبلی':'Previous Games',
    'سناریوها':'Scenarios','قوانین و سناریوهای بازی':'Game Rules & Scenarios','تنظیمات':'Settings','ظاهر، تم و صدای بازی':'Appearance, themes & sound',
    'انتخاب بازیکنان':'Select Players','لغو همه':'Deselect All','انتخاب همه':'Select All','تأیید':'Confirm','افزودن':'Add','افزودن بازیکن':'Add Player',
    'اسمِ بازیکنِ جدید':'New player name','هنوز کسی تو لیست نیست.':'No players yet.','انصراف':'Cancel','ذخیره':'Save','ویرایشِ اسم':'Edit Name',
    'بازیابی':'Restore','خروجی گرفتن':'Export','تاریخچه بازی‌ها':'Game History','آمار و عملکرد':'Stats & Performance','قوانین و نقش‌ها':'Rules & Roles',
    'نمایش نقش‌ها':'Reveal Roles','انتخابِ همه':'Select All','فاز دفاع':'Defense Phase','نوبت دفاع':'Defense Turn','پایان دفاع و نفر بعدی':'End Defense & Next',
    'نوبتِ':'Turn','در حال صحبت':'Speaking','چالش فعال':'Challenge Active','نفر بعدی':'Next Player','پایان چالش':'End Challenge','انتخاب چالش':'Choose Challenge',
    'کنترل میز بازی':'Table Controls','زمانِ صحبت':'Speaking Time','تایمر متوقف است':'Timer Paused','مکث':'Pause','پخش':'Start','توقف':'Stop',
  };

  static String roleName(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_roleNamesEn[id] ?? fallback)
          : fallback;

  static String roleDescription(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_roleDescriptionsEn[id] ?? fallback)
          : fallback;

  static String teamName(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_teamNamesEn[id] ?? fallback)
          : fallback;

  static String teamDescription(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_teamDescriptionsEn[id] ?? fallback)
          : fallback;

  static String scenarioName(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_scenarioNamesEn[id] ?? fallback)
          : fallback;

  static String scenarioDescription(String id, String fallback) =>
      AppLanguageController.current.value == AppLanguage.english
          ? (_scenarioDescriptionsEn[id] ?? fallback)
          : fallback;

  static const _roleNamesEn = <String, String>{
    'role_vali_faghih':'Supreme Leader','role_foreign_minister':'Foreign Minister','role_suppressor':'Suppressor',
    'role_judiciary_chief':'Judiciary Chief','role_doctor':'Doctor','role_hacker':'Hacker','role_revolutionary_fighter':'Revolutionary Fighter',
    'role_lawyer':'Lawyer','role_rapper':'Protest Rapper','role_zhina':'Zhina','role_government_celebrity':'Government Celebrity',
    'role_rebel':'Rebel','role_interrogator':'Investigative Journalist','role_intelligence_minister':'Intelligence Minister',
    'role_police_commander':'Police Commander','role_mercenary':'Plainclothes Mercenary','role_national_hero':'National Hero',
    'role_gray_citizen':'Gray Citizen','role_mossad_leader':'Mossad Leader','role_civic_activist':'Civic Activist',
    'role_political_analyst':'Political Analyst','role_godfather':'Godfather','role_negotiator':'Negotiator',
    'role_simple_mafia':'Simple Mafia','role_enchanter':'Enchanter','role_mafia_doctor':'Mafia Doctor','role_detective':'Detective',
    'role_professional':'Professional','role_konstantin':'Constantine','role_ocean':'Ocean','role_spy':'Spy','role_gunman':'Gunsmith',
    'role_kidnapper':'Kidnapper','role_terrorist':'Terrorist','role_simple_citizen':'Simple Citizen','role_zodiac':'Zodiac',
    'role_leader':'Leader','role_sherlock':'Sherlock','role_bomber':'Bomber','role_guard':'Guardian','role_mistress':'Mistress',
    'role_natasha':'Natasha','role_saboteur':'Saboteur','role_discloser':'Revealer','role_white_beard':'White Beard',
  };

  static const _roleDescriptionsEn = <String, String>{
    'role_vali_faghih':'Leader of the suppression team. Makes the final night decision and has a night armor.',
    'role_foreign_minister':'Can negotiate once to recruit a gray citizen into the suppression team after a teammate is eliminated.',
    'role_suppressor':'A basic suppression-team member with no special ability.',
    'role_judiciary_chief':'Once per game, announces a forbidden word; anyone saying it the next day is eliminated.',
    'role_doctor':'Protects one or more players from night attacks, with a limited number of self-saves.',
    'role_hacker':'Investigates whether a player belongs to the suppression team, subject to role-specific exceptions.',
    'role_revolutionary_fighter':'Can perform revolutionary executions or role-guessing slaughters with a limited total quota.',
    'role_lawyer':'Can revive one eliminated player; ordinary eliminations can remain half-alive until the revival is used.',
    'role_rapper':'Can attempt to recruit a player into the resistance; a wrong choice causes a delayed self-elimination.',
    'role_zhina':'When eliminated, disables the suppression team’s special ability on the following night.',
    'role_government_celebrity':'A suppression member who can appear innocent to the hacker for several early nights.',
    'role_rebel':'Can distribute real and practice weapons to players.',
    'role_interrogator':'Can perform a one-time interrogation of a player.',
    'role_intelligence_minister':'Can ask a special intelligence question during the night.',
    'role_police_commander':'Can detain a player during the night.',
    'role_mercenary':'Can assassinate a target as a special night action.',
    'role_national_hero':'Can guarantee or protect a player from a vote-related elimination.',
    'role_gray_citizen':'A basic citizen role without a special ability.',
    'role_mossad_leader':'Independent leader who chooses a night playstyle and later performs its corresponding action.',
    'role_civic_activist':'Can request a referendum once during the game.',
    'role_political_analyst':'Investigates whether a player belongs to the independent team.',
    'role_godfather':'Leader of the Mafia team who directs the night elimination and can use the team’s special powers.',
    'role_negotiator':'A Mafia support role focused on negotiation and recruitment.',
    'role_simple_mafia':'Basic Mafia member and loyal follower of the Godfather.',
    'role_enchanter':'Writes a cursed word; anyone saying it the next day leaves the game.',
    'role_mafia_doctor':'Mafia-side doctor who can protect players from night attacks.',
    'role_detective':'Investigates whether a player belongs to the Mafia team.',
    'role_professional':'Can eliminate a target with a professional kill, with special rules for role guesses.',
    'role_konstantin':'Can revive an eliminated player.',
    'role_ocean':'Leads the Ocean/resistance recruitment attempt.',
    'role_spy':'An infiltrator who can permanently enter the Ocean/resistance team when targeted.',
    'role_gunman':'Can distribute real and practice weapons.',
    'role_kidnapper':'Can kidnap or detain a player as a special night action.',
    'role_terrorist':'Can trigger a bomb-related elimination according to the Mafia scenario rules.',
    'role_simple_citizen':'Basic citizen role without a special ability.',
    'role_zodiac':'Independent role with its own win condition and night actions.',
    'role_leader':'Can seek consensus votes to lead the community.',
    'role_sherlock':'Investigates whether a player is the Zodiac.',
    'role_bomber':'Plants a bomb on a target; the bomb resolves according to the scenario rules.',
    'role_guard':'Protects citizens against the bomber and counters certain Zodiac attacks.',
    'role_mistress':'If eliminated while the Godfather is alive, enrages the Godfather for the following night.',
    'role_natasha':'Can silence one rival-team player for a limited period.',
    'role_saboteur':'Can sabotage a player’s weapon so a real shot can backfire.',
    'role_discloser':'Can reveal whether a selected player belongs to the Mafia when eliminated during the day.',
    'role_white_beard':'Can guarantee or protect a player from vote-related elimination.',
  };

  static const _teamNamesEn = <String, String>{
    'team_sorkoob':'Suppression','team_citizen':'Citizens','team_mossad':'Mossad','team_mek':'People’s Mojahedin Organization',
    'team_mafia_gang':'Mafia','team_mafia_town':'Citizens','team_zodiac':'Zodiac',
  };
  static const _teamDescriptionsEn = <String, String>{
    'team_sorkoob':'Government suppression forces seeking to eliminate opponents secretly.',
    'team_citizen':'Ordinary people and civic activists seeking to identify and eliminate suppressors.',
    'team_mossad':'An independent foreign operative with separate goals and actions.',
    'team_mek':'An armed opposition group with separate goals and actions.',
    'team_mafia_gang':'Mafia members who wake together and agree on a target at night.',
    'team_mafia_town':'Citizens with no special team ability who rely on voting and analysis.',
    'team_zodiac':'A mysterious independent operative with separate goals and actions.',
  };
  static const _scenarioNamesEn = <String, String>{
    'scenario_sorkoob':'Suppression','scenario_mafia':'Mafia',
  };
  static const _scenarioDescriptionsEn = <String, String>{
    'scenario_sorkoob':'An Iranian political-themed scenario pitting a government suppression team against citizens, with an optional independent team.',
    'scenario_mafia':'A classic Mafia scenario where the Mafia coordinates nightly eliminations against the town, with an optional independent team.',
  };

  static String get(String key) => t(key);
}

extension AppLocalizedString on String {
  String get tr => AppStrings.t(this);
}
