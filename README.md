# دست خدا

پلتفرم اجرای بازی‌های **Hidden Role / Mafia** برای گرداننده، با معماری چندسناریویی.

> نام محصول «دست خدا» است. **سرکوب فقط یکی از سناریوهای موجود است** و نباید در لایه‌های عمومی محصول به آن قفل شویم.

## وضعیت فعلی

- Flutter / Dart
- رابط کاربری مدرن با تم تاریک، طلایی و مناسب میز گرداننده
- مسیر کامل شروع بازی، انتخاب سناریو، تنظیم نقش‌ها، نمایش خصوصی نقش و اجرای بازی
- طراحی Responsive برای موبایل‌های کوچک و نمایشگرهای بزرگ‌تر
- سیستم 3D موجود برنامه در UI جدید حفظ شده است
- Dialog و BottomSheetها از Theme مشترک مدرن استفاده می‌کنند
- deprecatedهای UI از جمله `withOpacity` در کد UI پاک‌سازی شده‌اند

## معماری چندسناریویی

جریان عمومی برنامه بر پایه‌ی `GameScenario` طراحی شده است:

```text
Home
  ↓
ModernStartGameScreen
  ↓
انتخاب سناریو
  ↓
ModernRoleSetupScreen(scenario)
  ↓
StartGameScreen(initialScenario: scenario)
  ↓
RoleRevealScreen
  ↓
ModernGameFlowScreen
```

سناریو از مسیر شروع بازی انتخاب و به مراحل بعدی منتقل می‌شود؛ بنابراین UI عمومی نباید فرض کند که همیشه بازی «سرکوب» اجرا می‌شود.

### اصل مهم

کدهای مخصوص یک سناریو باید در لایه‌ی سناریوی همان بازی باقی بمانند و به UI/هسته‌ی عمومی نشت نکنند.

ساختار مورد انتظار:

```text
lib/
├── models/
│   ├── game_scenario.dart
│   ├── game_session.dart
│   ├── role.dart
│   └── team.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── modern_start_game_screen.dart
│   ├── modern_role_setup_screen.dart
│   ├── start_game_screen.dart
│   ├── role_reveal_screen.dart
│   ├── modern_game_flow_screen.dart
│   └── game_flow_screen.dart
│
├── scenario_sorkoob/
│   └── منطق و داده‌های اختصاصی سناریوی سرکوب
│
├── theme/
└── widgets/
```

## جریان شروع بازی

`ModernStartGameScreen` سناریو را در قالب `GameScenario` نگه می‌دارد و پس از انتخاب، همان سناریو را به مرحله‌ی تنظیم نقش‌ها منتقل می‌کند.

`ModernRoleSetupScreen` یک لایه‌ی بصری روی جریان اصلی `StartGameScreen` است و سناریوی انتخاب‌شده را با `initialScenario` وارد می‌کند. به این ترتیب state و منطق اصلی دوباره‌نویسی نشده‌اند.

`StartGameScreen` نیز `initialScenario` را دریافت کرده و سناریوی انتخاب‌شده را در ادامه‌ی جریان حفظ می‌کند.

## UI / Design System

تم عمومی برنامه در `lib/theme/app_theme.dart` متمرکز است و از رنگ‌های اصلی پروژه مانند:

- پس‌زمینه‌ی تیره
- سطح‌های تیره‌ی کارت
- طلایی
- طلایی روشن
- قرمز معنایی

استفاده می‌کند.

رنگ‌های اختصاصی نقش‌ها و تیم‌ها باید حفظ شوند و نباید با یک فیلتر رنگی سراسری جایگزین شوند.

ویجت‌های مشترک مهم:

- `Game3DButton`
- `Game3DSurface`
- `Game3DTile`
- `RoleInfoCard`
- `ModernSpeakingPanel`
- `ModernDefensePanel`
- `ModernNightPanel`
- `CountdownTimerWidget`

## Responsive

برای عرض‌های کوچک، padding و نسبت کارت‌ها به‌صورت پویا تنظیم شده‌اند. مسیرهای Home، Role Reveal و Roster باید روی موبایل‌های کوچک بدون overflow کار کنند و در نمایشگرهای بزرگ‌تر فضای مناسب‌تری بگیرند.

## نگهداری معماری

هنگام اضافه کردن سناریوی جدید:

1. سناریو را به مدل/registry سناریوها اضافه کنید.
2. نقش‌ها، تیم‌ها و قوانین اختصاصی را در لایه‌ی سناریوی خودش نگه دارید.
3. مسیر عمومی شروع بازی را تغییر ندهید مگر اینکه قابلیت واقعاً عمومی باشد.
4. از قرار دادن شرط‌هایی مثل «اگر سرکوب است» در UI عمومی خودداری کنید.
5. سناریوی انتخاب‌شده باید از Start Game تا Game Flow بدون hard-code شدن حفظ شود.

## نکته برای توسعه‌دهنده

**دست خدا = پلتفرم چندسناریویی**

**سرکوب = یک سناریو**

هر تغییر UI یا معماری جدید باید این تفکیک را حفظ کند.
