import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// پالتِ رنگیِ دکمه‌های سه‌بعدی. مستقیماً از AppColors می‌گیره (نه رنگِ
/// هاردکدِ جدید) تا با تمِ تیره+طلاییِ فعلی صد در صد هماهنگ بمونه.
enum Game3DPalette { gold, dark, danger }

/// مجموعه‌رنگِ یک پالت: بالا/پایینِ گرادیانِ روی دکمه، رنگِ لبه‌ی زیرین
/// (حسِ ضخامتِ فیزیکی)، رنگِ حاشیه، و رنگِ متن/آیکون.
class Game3DColors {
  final Color top;
  final Color bottom;
  final Color edge;
  final Color border;
  final Color text;

  const Game3DColors({
    required this.top,
    required this.bottom,
    required this.edge,
    required this.border,
    required this.text,
  });

  static const gold = Game3DColors(
    top: AppColors.goldLight,
    bottom: AppColors.gold,
    edge: AppColors.goldDark,
    border: AppColors.goldDark,
    text: Color(0xFF2A1B02),
  );

  static const dark = Game3DColors(
    top: AppColors.surfaceCard,
    bottom: AppColors.surfaceDark,
    edge: AppColors.background,
    border: AppColors.gold,
    text: AppColors.goldLight,
  );

  static const danger = Game3DColors(
    top: AppColors.bloodRedLight,
    bottom: AppColors.bloodRed,
    edge: Color(0xFF1E0505),
    border: AppColors.bloodRedLight,
    text: AppColors.goldLight,
  );

  static const disabled = Game3DColors(
    top: Color(0xFF4C4C4C),
    bottom: Color(0xFF2E2E2E),
    edge: Color(0xFF181818),
    border: Color(0xFF5A5A5A),
    text: Color(0xFF9A9A9A),
  );

  static Game3DColors of(Game3DPalette palette) {
    switch (palette) {
      case Game3DPalette.gold:
        return gold;
      case Game3DPalette.dark:
        return dark;
      case Game3DPalette.danger:
        return danger;
    }
  }
}

/// هسته‌ی مشترکِ همه‌ی دکمه‌های سه‌بعدی: گرادیانِ روشن‌به‌تیره + یه
/// «لبه‌ی توپر» زیرِ دکمه (با BoxShadow بدونِ بلور) که حسِ ضخامتِ
/// فیزیکی می‌ده، و موقعِ فشار با یه انیمیشنِ کوتاه جمع می‌شه (انگار
/// دکمه تو سطح فرو رفته). اندازه‌ش کاملاً از محتوا/والدش میاد — نه از
/// Stack دستی — پس هرجا بذاریش (تو یه Row، GridView، یا Column) رفتارِ
/// طبیعیِ چیدمانِ فلاتر رو داره؛ برای عرضِ کامل کافیه تو یه
/// `SizedBox(width: double.infinity)` یا `Column(crossAxisAlignment:
/// CrossAxisAlignment.stretch)` بذاریش.
class Game3DSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Game3DPalette palette;
  final BorderRadius borderRadius;
  final double depth;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  const Game3DSurface({
    super.key,
    required this.child,
    required this.onPressed,
    this.palette = Game3DPalette.gold,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.depth = 5,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.semanticLabel,
  });

  @override
  State<Game3DSurface> createState() => _Game3DSurfaceState();
}

class _Game3DSurfaceState extends State<Game3DSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || value == _pressed) return;
    setState(() => _pressed = value);
    if (value) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final c = enabled ? Game3DColors.of(widget.palette) : Game3DColors.disabled;
    final d = widget.depth;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: _pressed ? d : 0, bottom: _pressed ? 0 : d),
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.top, c.bottom],
            ),
            border: Border.all(color: c.border, width: 1.3),
            boxShadow: [
              BoxShadow(color: c.edge, offset: Offset(0, d), blurRadius: 0),
              if (!_pressed)
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  offset: Offset(0, d + 2),
                  blurRadius: 6,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// دکمه‌ی اکشنِ مستطیلی — جایگزینِ ElevatedButton برای اکشن‌های اصلی
/// («شروع بازی»، «شروع رأی‌گیری»، «تأیید»، ...). برای غیرفعال‌کردن،
/// onPressed رو null بده (دقیقاً مثلِ ElevatedButton).
class Game3DButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Game3DPalette palette;
  final double fontSize;

  const Game3DButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.palette = Game3DPalette.gold,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final c = enabled ? Game3DColors.of(palette) : Game3DColors.disabled;
    return Game3DSurface(
      onPressed: onPressed,
      palette: palette,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: c.text, size: fontSize + 6),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.text,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                shadows: [Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 1), blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// کاشیِ گریدِ منو — همون نقشِ MenuCardِ قبلی رو داره (menu_card.dart
/// الان فقط یه پوسته‌ی نازک دورِ همینه).
class Game3DTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Game3DPalette palette;

  const Game3DTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.palette = Game3DPalette.gold,
  });

  @override
  Widget build(BuildContext context) {
    final c = Game3DColors.of(palette);
    return Game3DSurface(
      onPressed: onTap,
      palette: palette,
      depth: 7,
      borderRadius: BorderRadius.circular(18),
      semanticLabel: title,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.18),
              border: Border.all(color: c.text.withOpacity(0.7), width: 1.4),
            ),
            child: Icon(icon, color: c.text, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// دکمه‌ی آیکونیِ دایره‌ای — برای هرجایی که فقط یه آیکونِ کوچیکِ
/// سه‌بعدی لازمه (نه لیبل).
class Game3DIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Game3DPalette palette;
  final double size;
  final String? tooltip;

  const Game3DIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.palette = Game3DPalette.dark,
    this.size = 46,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final c = enabled ? Game3DColors.of(palette) : Game3DColors.disabled;
    final button = Game3DSurface(
      onPressed: onPressed,
      palette: palette,
      borderRadius: BorderRadius.circular(size),
      depth: 4,
      padding: EdgeInsets.zero,
      semanticLabel: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: c.text, size: size * 0.5),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// دکمه‌ی نوارِ پایینِ گردانندگی — دقیقاً همون امضایِ متدِ قدیمیِ
/// `_bottomBarAction` (icon, label, onPressed, active) رو داره، برای
/// جایگزینیِ بدونِ درد. active=true یعنی «روشن/فعال» → پالتِ طلایی؛
/// وگرنه پالتِ تیره‌ی خنثی.
class Game3DBottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  const Game3DBottomBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = active ? Game3DPalette.gold : Game3DPalette.dark;
    final c = Game3DColors.of(palette);
    return Game3DSurface(
      onPressed: onPressed,
      palette: palette,
      depth: 4,
      borderRadius: BorderRadius.circular(13),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.text, size: 20),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: c.text, fontSize: 9.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
