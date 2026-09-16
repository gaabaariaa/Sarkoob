import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// رنگ‌های ثابتِ هویت بازی.
/// این پالت مخصوص نقش‌ها، تیم‌ها و رنگ‌های معنایی سناریو است و با تم UI تغییر نمی‌کند.
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
    current.value = AppThemeId.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppThemeId.darkGold,
    );
  }

  static Future<void> set(AppThemeId theme) async {
    current.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}

class AppTheme {
  static ThemeData get darkGoldTheme => _build(
        seed: AppColors.gold,
        background: AppColors.background,
        surface: AppColors.surfaceDark,
        card: AppColors.surfaceCard,
        elevated: AppColors.surfaceElevated,
        primary: AppColors.gold,
        primaryLight: AppColors.goldLight,
        primaryDark: AppColors.goldDark,
      );

  static ThemeData get midnightTheme => _build(
        seed: const Color(0xFF7895B2),
        background: const Color(0xFF070B10),
        surface: const Color(0xFF0F151D),
        card: const Color(0xFF151D27),
        elevated: const Color(0xFF1C2733),
        primary: const Color(0xFF9DB9D5),
        primaryLight: const Color(0xFFD7E6F4),
        primaryDark: const Color(0xFF5D7690),
      );

  static ThemeData get crimsonTheme => _build(
        seed: const Color(0xFFB84A4A),
        background: const Color(0xFF0B0809),
        surface: const Color(0xFF171013),
        card: const Color(0xFF211519),
        elevated: const Color(0xFF2A191E),
        primary: const Color(0xFFB84A4A),
        primaryLight: const Color(0xFFE58A8A),
        primaryDark: const Color(0xFF7D2929),
      );

  static ThemeData forId(AppThemeId id) {
    switch (id) {
      case AppThemeId.darkGold:
        return darkGoldTheme;
      case AppThemeId.midnight:
        return midnightTheme;
      case AppThemeId.crimson:
        return crimsonTheme;
    }
  }

  static ThemeData _build({
    required Color seed,
    required Color background,
    required Color surface,
    required Color card,
    required Color elevated,
    required Color primary,
    required Color primaryLight,
    required Color primaryDark,
  }) {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.black,
      secondary: primaryLight,
      onSecondary: Colors.black,
      surface: surface,
      error: AppColors.bloodRedLight,
      onSurface: Colors.white,
    );

    final bodyFont = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: primaryLight,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: bodyFont,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: primaryLight,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.lalezar(fontSize: 21, color: primaryLight, height: 1.15),
        iconTheme: IconThemeData(color: primaryLight),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: primary.withOpacity(0.12)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.lalezar(fontSize: 21, color: primaryLight),
        contentTextStyle: bodyFont.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: primaryLight.withOpacity(0.25)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: primary.withOpacity(0.55)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: primary.withOpacity(0.55)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary : Colors.white38),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? primary.withOpacity(0.35) : Colors.white12),
      ),
      dividerTheme: DividerThemeData(
        color: primary.withOpacity(0.14),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary, width: 1.2),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
      ),
    );
  }

  static TextStyle headingFont({double size = 28, Color? color}) {
    return GoogleFonts.lalezar(
      fontSize: size,
      color: color ?? AppColors.goldLight,
      height: 1.15,
    );
  }
}
