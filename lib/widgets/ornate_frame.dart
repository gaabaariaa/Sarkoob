import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یه قاب تزئینی طلایی با نشان‌های کوچیک در چهار گوشه.
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

/// یه جداکننده‌ی تزئینی: خط--نشان--خط، برای زیر عنوان‌های اصلی.
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

/// قابِ تزئینیِ سبک برایِ رویِ کلِ صفحه: فقط خط‌ها و نشانِ گوشه‌ها،
/// بدونِ جعبه‌ی دورِ یه child خاص. برخلافِ [OrnateFrame] بالا (که یه
/// child می‌گیره و دورش قاب می‌کشه)، این یکی با Positioned.fill رویِ
/// همه‌چیزِ دیگه‌ی صفحه کشیده می‌شه — برایِ بازطراحیِ صفحه‌ی اصلی اضافه شد.
class OrnateCornerOverlay extends StatelessWidget {
  const OrnateCornerOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _CornerOverlayPainter()));
}

class _CornerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.gold.withOpacity(.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    const inset = 12.0;
    const corner = 27.0;
    final path = Path()
      ..moveTo(inset + corner, inset)
      ..lineTo(size.width - inset - corner, inset)
      ..moveTo(inset, inset + corner)
      ..lineTo(inset, size.height - inset - corner)
      ..moveTo(size.width - inset, inset + corner)
      ..lineTo(size.width - inset, size.height - inset - corner)
      ..moveTo(inset + corner, size.height - inset)
      ..lineTo(size.width - inset - corner, size.height - inset);
    canvas.drawPath(path, linePaint);

    final ornamentPaint = Paint()
      ..color = AppColors.gold.withOpacity(.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final alignment in const [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ]) {
      final x = alignment.x < 0 ? inset : size.width - inset;
      final y = alignment.y < 0 ? inset : size.height - inset;
      final sx = alignment.x < 0 ? 1.0 : -1.0;
      final sy = alignment.y < 0 ? 1.0 : -1.0;
      final ornament = Path()
        ..moveTo(x, y + sy * 21)
        ..quadraticBezierTo(x + sx * 2, y + sy * 7, x + sx * 15, y)
        ..moveTo(x + sx * 3, y + sy * 12)
        ..quadraticBezierTo(x + sx * 9, y + sy * 9, x + sx * 11, y + sy * 3)
        ..moveTo(x + sx * 9, y + sy * 18)
        ..quadraticBezierTo(x + sx * 15, y + sy * 14, x + sx * 19, y + sy * 7);
      canvas.drawPath(ornament, ornamentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
