import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import 'start_game_screen.dart';

/// پوسته‌ی مرحله‌ی «تنظیم نقش».
///
/// تمام state و منطق واقعی تنظیم بازیکنان، تیم‌ها و نقش‌ها در
/// [StartGameScreen] باقی می‌ماند؛ این کلاس فقط آن جریان را با زبان بصری
/// یکپارچه‌ی «دست خدا» وارد می‌کند.
class ModernRoleSetupScreen extends StatelessWidget {
  final GameScenario scenario;

  const ModernRoleSetupScreen({
    super.key,
    required this.scenario,
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
        titleTextStyle: AppTheme.headingFont(size: 21).copyWith(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: AppColors.goldLight),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.gold.withOpacity(.10)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.gold.withOpacity(.14)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.surfaceDark,
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
    );

    return Theme(
      data: themed,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.9),
                    radius: 1.2,
                    colors: [
                      scenario.color.withOpacity(.08),
                      AppColors.background,
                    ],
                    stops: const [0, .72],
                  ),
                ),
              ),
            ),
          ),
          StartGameScreen(initialScenario: scenario),
        ],
      ),
    );
  }
}
