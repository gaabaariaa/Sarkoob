import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یکی از ۶ کارت منوی صفحه‌ی اصلی (شروع بازی، بازیکنان، آمار، ...).
/// این نسخه ظاهرِ شیشه‌ایِ پرمیوم داره (بلور + گرادیانِ طلایی/شرابی)،
/// الهام‌گرفته از طرحِ ارجاعیِ کاربر — مستقل از سیستمِ Game3DTile
/// (که رول‌ریویل و جاهایِ دیگه هنوز ازش استفاده می‌کنن، دست‌نخورده مونده).
class MenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? .975 : 1,
          duration: const Duration(milliseconds: 110),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(_pressed ? .11 : .075),
                      AppColors.bloodRed.withOpacity(_pressed ? .58 : .43),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(_pressed ? .9 : .58),
                    width: 1.15,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(_pressed ? .18 : .08),
                      blurRadius: _pressed ? 22 : 14,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(.48),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -18,
                      bottom: -28,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppColors.bloodRedLight.withOpacity(.38),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(.20),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(.72),
                                  width: 1.05,
                                ),
                              ),
                              child: Icon(widget.icon, size: 28, color: AppColors.goldLight),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: AppTheme.menuLabel(size: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
