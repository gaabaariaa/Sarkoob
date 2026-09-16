import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_flow_screen.dart';

/// پوسته‌ی بصری مرحله‌ی گردانندگی.
/// GameFlowScreen اصلی عمداً بدون دستکاری باقی می‌ماند تا تمام منطق سناریو،
/// اکشن‌ها، تایمرها و وضعیت بازی همان قبلی باشد؛ این کلاس فقط زبان بصری
/// مشترک «دست خدا» را روی کنترل‌های متریال اعمال می‌کند.
class ModernGameFlowScreen extends StatelessWidget {
  final List<dynamic> players;
  final dynamic settings;

  const ModernGameFlowScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final themed = base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.goldLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.headingFont(size: 21).copyWith(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.gold.withOpacity(.10)),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: AppColors.gold.withOpacity(.10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.goldLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.gold.withOpacity(.28)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          minimumSize: const Size.fromHeight(46),
          side: BorderSide(color: AppColors.gold.withOpacity(.28)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.surfaceDark,
        labelStyle: const TextStyle(color: AppColors.mutedText),
        hintStyle: const TextStyle(color: AppColors.subtleText),
        prefixIconColor: AppColors.goldLight,
        suffixIconColor: AppColors.goldLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: AppColors.background,
        elevation: 0,
      ),
    );

    return Theme(
      data: themed,
      child: Stack(
        children: [
          const _GameAmbient(),
          GameFlowScreen(
            players: players.cast(),
            settings: settings,
          ),
        ],
      ),
    );
  }
}

class _GameAmbient extends StatelessWidget {
  const _GameAmbient();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.15,
              colors: [Color(0x18D4AF37), Color(0x0008090B)],
              stops: [0, .72],
            ),
          ),
        ),
      ),
    );
  }
}
