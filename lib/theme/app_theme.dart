import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// رنگ‌های ثابتِ هویت بازی. این پالت مخصوص نقش‌ها، تیم‌ها و رنگ‌های معنایی سناریو است و با تم UI تغییر نمی‌کند.
class AppColors {
  static const background = Color(0xFF08090B);
  static const surfaceDark = Color(0xFF111318);
  static const surfaceCard = Color(0xFF171A20);
  static const surfaceElevated = Color(0xFF1D1A16);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF1D989);
  static const goldDark = Color(0xFF8A6D1D);
  static const bloodRed = Color(0xFF3D0C0C);
  static const bloodRedLight = Color(0xFF6B1414);
  static const mutedText = Color(0xFF9B9DA4);
  static const subtleText = Color(0xFF686B73);
}

enum AppThemeId { darkGold, midnight, crimson }

class AppThemeController {
  static const _key = 'app_theme';
  static final ValueNotifier<AppThemeId> current = ValueNotifier(AppThemeId.darkGold);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    current.value = AppThemeId.values.firstWhere((theme) => theme.name == value, orElse: () => AppThemeId.darkGold);
  }

  static Future<void> set(AppThemeId theme) async {
    current.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}

class AppTheme {
  static Color get uiBackground => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.background,
    AppThemeId.midnight => const Color(0xFF070B10),
    AppThemeId.crimson => const Color(0xFF0B0809),
  };
  static Color get uiSurface => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.surfaceDark,
    AppThemeId.midnight => const Color(0xFF0F151D),
    AppThemeId.crimson => const Color(0xFF171013),
  };
  static Color get uiCard => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.surfaceCard,
    AppThemeId.midnight => const Color(0xFF151D27),
    AppThemeId.crimson => const Color(0xFF211519),
  };
  static Color get uiElevated => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.surfaceElevated,
    AppThemeId.midnight => const Color(0xFF1C2733),
    AppThemeId.crimson => const Color(0xFF2A191E),
  };
  static Color get uiPrimary => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.gold,
    AppThemeId.midnight => const Color(0xFF9DB9D5),
    AppThemeId.crimson => const Color(0xFFB84A4A),
  };
  static Color get uiPrimaryLight => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.goldLight,
    AppThemeId.midnight => const Color(0xFFD7E6F4),
    AppThemeId.crimson => const Color(0xFFE58A8A),
  };
  static Color get uiPrimaryDark => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.goldDark,
    AppThemeId.midnight => const Color(0xFF5D7690),
    AppThemeId.crimson => const Color(0xFF7D2929),
  };
  static Color get uiMutedText => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.mutedText,
    AppThemeId.midnight => const Color(0xFFAAB7C6),
    AppThemeId.crimson => const Color(0xFFB5A5A8),
  };
  static Color get uiSubtleText => switch (AppThemeController.current.value) {
    AppThemeId.darkGold => AppColors.subtleText,
    AppThemeId.midnight => const Color(0xFF68788A),
    AppThemeId.crimson => const Color(0xFF75656A),
  };

  static ThemeData get darkGoldTheme => _build(seed: AppColors.gold, background: AppColors.background, surface: AppColors.surfaceDark, card: AppColors.surfaceCard, elevated: AppColors.surfaceElevated, primary: AppColors.gold, primaryLight: AppColors.goldLight, primaryDark: AppColors.goldDark);
  static ThemeData get midnightTheme => _build(seed: const Color(0xFF7895B2), background: const Color(0xFF070B10), surface: const Color(0xFF0F151D), card: const Color(0xFF151D27), elevated: const Color(0xFF1C2733), primary: const Color(0xFF9DB9D5), primaryLight: const Color(0xFFD7E6F4), primaryDark: const Color(0xFF5D7690));
  static ThemeData get crimsonTheme => _build(seed: const Color(0xFFB84A4A), background: const Color(0xFF0B0809), surface: const Color(0xFF171013), card: const Color(0xFF211519), elevated: const Color(0xFF2A191E), primary: const Color(0xFFB84A4A), primaryLight: const Color(0xFFE58A8A), primaryDark: const Color(0xFF7D2929));

  static ThemeData forId(AppThemeId id) => switch (id) {
    AppThemeId.darkGold => darkGoldTheme,
    AppThemeId.midnight => midnightTheme,
    AppThemeId.crimson => crimsonTheme,
  };

  static ThemeData _build({required Color seed, required Color background, required Color surface, required Color card, required Color elevated, required Color primary, required Color primaryLight, required Color primaryDark}) {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(primary: primary, onPrimary: Colors.black, secondary: primaryLight, onSecondary: Colors.black, surface: surface, error: AppColors.bloodRedLight, onSurface: Colors.white);
    final bodyFont = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(bodyColor: Colors.white, displayColor: primaryLight);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: bodyFont,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(backgroundColor: background, elevation: 0, centerTitle: true, foregroundColor: primaryLight, scrolledUnderElevation: 0, titleTextStyle: GoogleFonts.lalezar(fontSize: 21, color: primaryLight, height: 1.15), iconTheme: IconThemeData(color: primaryLight)),
      cardTheme: CardThemeData(color: card, elevation: 0, margin: EdgeInsets.zero, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: primary.withAlpha(31)))),
      listTileTheme: ListTileThemeData(tileColor: card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), iconColor: primaryLight, textColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3)),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: primary.withAlpha(77),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: primary.withAlpha(36)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black54,
        barrierColor: Colors.black.withAlpha(184),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titleTextStyle: TextStyle(
          color: primaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.5,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primary.withAlpha(41)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.black, minimumSize: const Size(0, 50), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: primaryLight, minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), side: BorderSide(color: primary.withAlpha(140)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryLight, textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : Colors.white38), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary.withAlpha(89) : Colors.white12), trackOutlineColor: WidgetStateProperty.all(primary.withAlpha(46))),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : Colors.white38)),
      checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : Colors.transparent), checkColor: WidgetStateProperty.all(Colors.black), side: BorderSide(color: primary.withAlpha(140))),
      iconTheme: IconThemeData(color: primaryLight),
      dividerTheme: DividerThemeData(color: primary.withAlpha(36), thickness: 1, space: 1),
      sliderTheme: SliderThemeData(activeTrackColor: primary, inactiveTrackColor: primary.withAlpha(46), thumbColor: primaryLight, overlayColor: primary.withAlpha(31)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primary.withAlpha(31))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primary.withAlpha(31))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primary, width: 1.2)), labelStyle: TextStyle(color: primaryLight.withAlpha(199)), floatingLabelStyle: TextStyle(color: primaryLight), hintStyle: TextStyle(color: Colors.white.withAlpha(97))),
    );
  }

  static TextStyle headingFont({double size = 28, Color? color}) => GoogleFonts.lalezar(fontSize: size, color: color ?? uiPrimaryLight, height: 1.15);
}

/// Compatibility facade for the modern screens. It reads the same dynamic UI palette
/// without touching the fixed role/team colors in AppColors.
class AppThemeExtension {
  final Color background;
  final Color surfaceDark;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color mutedText;
  final Color subtleText;

  const AppThemeExtension({
    required this.background,
    required this.surfaceDark,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.mutedText,
    required this.subtleText,
  });

  static AppThemeExtension of(BuildContext context) => AppThemeExtension(
    background: AppTheme.uiBackground,
    surfaceDark: AppTheme.uiSurface,
    surfaceCard: AppTheme.uiCard,
    surfaceElevated: AppTheme.uiElevated,
    accent: AppTheme.uiPrimary,
    accentLight: AppTheme.uiPrimaryLight,
    accentDark: AppTheme.uiPrimaryDark,
    mutedText: AppTheme.uiMutedText,
    subtleText: AppTheme.uiSubtleText,
  );
}
