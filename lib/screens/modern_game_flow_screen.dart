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

  ModernGameFlowScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final themed = base.copyWith(
      scaffoldBackgroundColor: AppTheme.uiBackground,
      canvasColor: AppTheme.uiBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppTheme.uiPrimary,
        secondary: AppTheme.uiPrimaryLight,
        surface: AppTheme.uiCard,
        onSurface: Colors.white,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppTheme.uiBackground,
        foregroundColor: AppTheme.uiPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.headingFont(size: 21).copyWith(
          color: AppTheme.uiPrimaryLight,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: AppTheme.uiPrimaryLight),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppTheme.uiCard,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppTheme.uiPrimary.withAlpha(26)),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        tileColor: AppTheme.uiCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: AppTheme.uiPrimaryLight,
        textColor: Colors.white,
        subtitleTextStyle: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: AppTheme.uiPrimary.withAlpha(26),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(48),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          backgroundColor: AppTheme.uiElevated,
          foregroundColor: AppTheme.uiPrimaryLight,
          disabledBackgroundColor: AppTheme.uiSurface,
          disabledForegroundColor: AppTheme.uiSubtleText,
          elevation: 0,
          textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppTheme.uiPrimary.withAlpha(71)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.uiPrimaryLight,
          minimumSize: Size.fromHeight(46),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: AppTheme.uiPrimary.withAlpha(71)),
          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.uiPrimaryLight,
          textStyle: TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppTheme.uiPrimaryLight,
          backgroundColor: AppTheme.uiSurface.withAlpha(184),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppTheme.uiSurface,
        labelStyle: TextStyle(color: AppTheme.uiMutedText),
        hintStyle: TextStyle(color: AppTheme.uiSubtleText),
        prefixIconColor: AppTheme.uiPrimaryLight,
        suffixIconColor: AppTheme.uiPrimaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(31)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(31)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.uiPrimary),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppTheme.uiSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppTheme.uiPrimary.withAlpha(36)),
        ),
        titleTextStyle: AppTheme.headingFont(size: 19).copyWith(
          color: AppTheme.uiPrimaryLight,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: Colors.white70, fontSize: 13),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppTheme.uiElevated,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: AppTheme.uiPrimary,
        circularTrackColor: AppTheme.uiPrimaryDark.withAlpha(51),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: AppTheme.uiBackground,
        elevation: 0,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: AppTheme.uiSurface,
        selectedItemColor: AppTheme.uiPrimaryLight,
        unselectedItemColor: AppTheme.uiSubtleText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );

    return Theme(
      data: themed,
      child: Stack(
        children: [
          _GameAmbient(),
          GameFlowScreen(players: players, settings: settings),
        ],
      ),
    );
  }
}

class _GameAmbient extends StatelessWidget {
  _GameAmbient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
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
