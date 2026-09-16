import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// پالت اصلی رابط کاربری: تیره، سینمایی و طلایی؛ با کنتراست کافی برای استفاده‌ی طولانی.
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

class AppTheme {
  static ThemeData get darkGoldTheme {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.gold,
      onPrimary: const Color(0xFF241A04),
      secondary: AppColors.goldLight,
      surface: AppColors.surfaceDark,
      error: AppColors.bloodRedLight,
      onSurface: Colors.white,
    );

    final bodyFont = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: AppColors.goldLight,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: bodyFont,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.goldLight,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.gold.withOpacity(0.12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.gold.withOpacity(0.14),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
      ),
    );
  }

  /// فونت تزئینی برای عنوان‌های بزرگ.
  static TextStyle headingFont({double size = 28, Color? color}) {
    return GoogleFonts.lalezar(
      fontSize: size,
      color: color ?? AppColors.goldLight,
      height: 1.15,
    );
  }
}
