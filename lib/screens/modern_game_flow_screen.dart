import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../theme/app_theme.dart';
import 'game_flow_screen.dart';

/// پوسته‌ی بصری مرحله‌ی گردانندگی.
/// منطق GameFlowScreen و سناریو عمداً دست‌نخورده می‌ماند؛ این کلاس فقط
/// زبان بصری مشترک «دست خدا» را روی تمام کنترل‌های فازهای بازی اعمال می‌کند.
class ModernGameFlowScreen extends StatelessWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;

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
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.surfaceCard,
        onSurface: Colors.white,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.goldLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.headingFont(size: 21).copyWith(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: AppColors.goldLight),
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
      listTileTheme: base.listTileTheme.copyWith(
        tileColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: AppColors.goldLight,
        textColor: Colors.white,
        subtitleTextStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: AppColors.gold.withOpacity(.10),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.goldLight,
          disabledBackgroundColor: AppColors.surfaceDark,
          disabledForegroundColor: AppColors.subtleText,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: AppColors.gold.withOpacity(.28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          backgroundColor: AppColors.surfaceDark.withOpacity(.72),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.gold.withOpacity(.14)),
        ),
        titleTextStyle: AppTheme.headingFont(size: 19).copyWith(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: AppColors.gold,
        circularTrackColor: AppColors.goldDark.withOpacity(.20),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: AppColors.background,
        elevation: 0,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.goldLight,
        unselectedItemColor: AppColors.subtleText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );

    return Theme(
      data: themed,
      child: Stack(
        children: [
          const _GameAmbient(),
          GameFlowScreen(players: players, settings: settings),
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
