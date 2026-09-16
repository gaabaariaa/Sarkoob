import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ornate_frame.dart';

/// Shared visual shell for the new «دست خدا» brand.
/// It only controls presentation; game/scenario state remains elsewhere.
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15120D), AppColors.background, Color(0xFF070708)],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _Glow(size: 300, color: AppColors.gold)),
          Positioned(bottom: -150, left: -100, child: _Glow(size: 340, color: AppColors.bloodRedLight)),
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BackdropPatternPainter())),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(0.12), Colors.transparent]),
      ),
    );
  }
}

class _BackdropPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withOpacity(0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height * 0.24);
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(center, i * 58.0, paint);
    }

    final linePaint = Paint()
      ..color = AppColors.gold.withOpacity(0.035)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandHeader extends StatelessWidget {
  final bool compact;
  const BrandHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: compact ? 58 : 72,
          height: compact ? 58 : 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goldLight, AppColors.gold],
            ),
            border: Border.all(color: AppColors.goldLight.withOpacity(0.75), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withOpacity(0.18), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Icon(
            Icons.back_hand_rounded,
            color: const Color(0xFF211704),
            size: compact ? 31 : 39,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Text('دست خدا', style: AppTheme.headingFont(size: compact ? 30 : 40)),
        if (!compact) ...[
          const SizedBox(height: 3),
          Text(
            'دستیار حرفه‌ای گرداننده',
            style: TextStyle(
              color: AppColors.goldLight.withOpacity(0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const OrnateDivider(lineWidth: 48),
          const SizedBox(height: 9),
          Text(
            'سناریوی فعال: سرکوب',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
