import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یه قاب تزئینی طلایی با نشان‌های کوچیک در چهار گوشه.
class OrnateFrame extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  OrnateFrame({
    super.key,
    required this.child,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(140), width: 1.2),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(71),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        Positioned(top: -6, left: -6, child: _CornerMark()),
        Positioned(top: -6, right: -6, child: _CornerMark()),
        Positioned(bottom: -6, left: -6, child: _CornerMark()),
        Positioned(bottom: -6, right: -6, child: _CornerMark()),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  _CornerMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.uiPrimary, width: 1.2),
        color: AppTheme.uiBackground,
      ),
    );
  }
}

/// یه جداکننده‌ی تزئینی: خط--نشان--خط، برای زیر عنوان‌های اصلی.
class OrnateDivider extends StatelessWidget {
  final double lineWidth;

  OrnateDivider({super.key, this.lineWidth = 60});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: lineWidth, height: 1, color: AppTheme.uiPrimary),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.star, size: 12, color: AppTheme.uiPrimary),
        ),
        Container(width: lineWidth, height: 1, color: AppTheme.uiPrimary),
      ],
    );
  }
}
