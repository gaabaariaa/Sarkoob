import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یه قاب تزئینی طلایی با نشان‌های کوچیک لوزی‌شکل در چهار گوشه —
/// جایگزین ساده‌ی حاشیه‌های تزئینیِ کلاسیک، بدون نیاز به فایل تصویری خاص.
/// اگه بعداً یه فریم گرافیکی اختصاصی (PNG/SVG) داشتید، همینجا می‌تونیم
/// جایگزینش کنیم.
class OrnateFrame extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const OrnateFrame({
    super.key,
    required this.child,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withOpacity(0.85), width: 1.2),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
        const Positioned(top: -6, left: -6, child: _CornerMark()),
        const Positioned(top: -6, right: -6, child: _CornerMark()),
        const Positioned(bottom: -6, left: -6, child: _CornerMark()),
        const Positioned(bottom: -6, right: -6, child: _CornerMark()),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.2),
        color: AppColors.background,
      ),
    );
  }
}

/// یه جداکننده‌ی تزئینی: خط--لوزی--خط، برای زیر عنوان‌های اصلی.
class OrnateDivider extends StatelessWidget {
  final double lineWidth;

  const OrnateDivider({super.key, this.lineWidth = 60});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: lineWidth, height: 1, color: AppColors.gold),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.star, size: 12, color: AppColors.gold),
        ),
        Container(width: lineWidth, height: 1, color: AppColors.gold),
      ],
    );
  }
}
