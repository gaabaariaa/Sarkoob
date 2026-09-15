import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// پالت رنگی اصلی اپ: تم تیره‌ی تجملی با لهجه‌ی طلایی، الهام‌گرفته از
/// حس‌وحال فیلم‌های مافیایی کلاسیک — بدون استفاده از هیچ تصویر یا
/// کاراکتر کپی‌رایتی خاصی.
class AppColors {
  static const background = Color(0xFF0B0B0D);
  static const surfaceDark = Color(0xFF19160F);
  static const surfaceCard = Color(0xFF1F1B12);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF1D989);
  static const goldDark = Color(0xFF8A6D1D);
  static const bloodRed = Color(0xFF3D0C0C);
  static const bloodRedLight = Color(0xFF6B1414);
}

class AppTheme {
  static ThemeData get darkGoldTheme {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
      surface: AppColors.surfaceDark,
      error: AppColors.bloodRedLight,
    );

    final bodyFont = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: AppColors.goldLight,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: bodyFont,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.goldLight,
      ),
      dividerColor: AppColors.gold.withOpacity(0.3),
    );
  }

  /// فونت تزئینی برای عنوان‌های بزرگ (اسم سناریو، تیتر صفحه‌ها)
  static TextStyle headingFont({double size = 28, Color? color}) {
    return GoogleFonts.lalezar(
      fontSize: size,
      color: color ?? AppColors.goldLight,
    );
  }

  /// استایلِ لیبلِ زیرِ آیکون در کارت‌های شیشه‌ایِ منویِ صفحه‌ی اصلی
  /// (این نسخه، برایِ بازطراحیِ صفحه‌ی اصلی اضافه شد).
  static TextStyle menuLabel({double size = 15}) {
    return GoogleFonts.vazirmatn(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: AppColors.goldLight,
      height: 1.15,
    );
  }
}
