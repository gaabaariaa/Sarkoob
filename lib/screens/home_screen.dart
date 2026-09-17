import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'roster_screen.dart';
import 'stats_screen.dart';
import 'history_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'modern_start_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _open(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.uiPrimary, light = AppTheme.uiPrimaryLight, dark = AppTheme.uiPrimaryDark;
    final bg = AppTheme.uiBackground, card = AppTheme.uiCard, surface = AppTheme.uiSurface, muted = AppTheme.uiMutedText;
    return Scaffold(body: Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: bg, gradient: RadialGradient(center: const Alignment(0, -.85), radius: 1.15, colors: [primary.withOpacity(.11), bg], stops: const [0, .72])), child: Stack(children: [Positioned(top: -90, right: -70, child: _GlowOrb(size: 220, color: primary, opacity: .045)), Positioned(bottom: 40, left: -100, child: _GlowOrb(size: 260, color: primary, opacity: .025))]))),
      SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 650;
        return SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: EdgeInsets.fromLTRB(wide ? 40 : 18, 18, wide ? 40 : 18, 28), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 920), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _TopBar(primary: primary, light: light, card: card, muted: muted), const SizedBox(height: 18),
          _HeroPanel(primary: primary, light: light, surface: surface, muted: muted), const SizedBox(height: 20),
          _StartButton(onTap: () => _open(context, const ModernStartGameScreen()), primary: primary, light: light), const SizedBox(height: 22),
          _SectionTitle(title: 'مدیریت بازی', primary: light), const SizedBox(height: 10),
          GridView.count(crossAxisCount: wide ? 3 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: wide ? 1.55 : 1.28, children: [
            _HomeTile(title: 'بازیکنان', subtitle: 'لیست و نقش‌ها', icon: Icons.groups_rounded, onTap: () => _open(context, const RosterScreen()), primary: primary, dark: dark, card: card, muted: muted),
            _HomeTile(title: 'آمار', subtitle: 'نتایج و عملکرد', icon: Icons.insights_rounded, onTap: () => _open(context, const StatsScreen()), primary: primary, dark: dark, card: card, muted: muted),
            _HomeTile(title: 'تاریخچه', subtitle: 'بازی‌های قبلی', icon: Icons.history_rounded, onTap: () => _open(context, const HistoryScreen()), primary: primary, dark: dark, card: card, muted: muted),
            _HomeTile(title: 'قوانین', subtitle: 'راهنمای سناریو', icon: Icons.menu_book_rounded, onTap: () => _open(context, const RulesScreen()), primary: primary, dark: dark, card: card, muted: muted),
          ]), const SizedBox(height: 12),
          _SettingsButton(onTap: () => _open(context, const SettingsScreen()), primary: primary, light: light, dark: dark, muted: muted), const SizedBox(height: 18),
          Text('دست خدا  •  سناریوی سرکوب', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: dark, letterSpacing: .2)),
        ]))));
      }))
    ]));
  }
}

class _GlowOrb extends StatelessWidget {
  final double size, opacity; final Color color;
  const _GlowOrb({required this.size, required this.color, required this.opacity});
  @override Widget build(BuildContext context) => ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity))));
}

class _TopBar extends StatelessWidget {
  final Color primary, light, card, muted;
  const _TopBar({required this.primary, required this.light, required this.card, required this.muted});
  @override Widget build(BuildContext context) => Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: card, border: Border.all(color: primary.withOpacity(.28))), child: Icon(Icons.auto_awesome, color: light, size: 22)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('دست خدا', style: AppTheme.headingFont(size: 25, color: light)), Text('دستیار گرداننده بازی نقش مخفی', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted))])), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: primary.withOpacity(.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: primary.withOpacity(.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)), const SizedBox(width: 6), Text('آماده', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: light, fontWeight: FontWeight.w700))]))]);
}

class _HeroPanel extends StatelessWidget {
  final Color primary, light, surface, muted;
  const _HeroPanel({required this.primary, required this.light, required this.surface, required this.muted});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(22, 25, 22, 22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppTheme.uiElevated, surface]), border: Border.all(color: primary.withOpacity(.24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 12))]), child: Column(children: [Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, primary]), boxShadow: [BoxShadow(color: primary.withOpacity(.18), blurRadius: 26, spreadRadius: 2)]), child: const Icon(Icons.theater_comedy_rounded, color: Color(0xFF151515), size: 38)), const SizedBox(height: 16), Text('میز بازی', style: AppTheme.headingFont(size: 31, color: light)), const SizedBox(height: 4), Text('همه‌چیز برای اجرای یک شب پرتنش آماده است.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.7)), const SizedBox(height: 17), Row(mainAxisAlignment: MainAxisAlignment.center, children: [_HeroTag(icon: Icons.shield_outlined, text: 'نقش مخفی', primary: primary, light: light), const SizedBox(width: 8), _HeroTag(icon: Icons.nights_stay_outlined, text: 'سناریوی سرکوب', primary: primary, light: light)])]));
}

class _HeroTag extends StatelessWidget {
  final IconData icon; final String text; final Color primary, light;
  const _HeroTag({required this.icon, required this.text, required this.primary, required this.light});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.black.withOpacity(.18), borderRadius: BorderRadius.circular(14), border: Border.all(color: primary.withOpacity(.14))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: primary), const SizedBox(width: 5), Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: light))]));
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap; final Color primary, light;
  const _StartButton({required this.onTap, required this.primary, required this.light});
  @override Widget build(BuildContext context) => Game3DSurface(onPressed: onTap, customColors: Game3DColors.fromColor(primary), depth: 6, borderRadius: BorderRadius.circular(19), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), semanticLabel: 'شروع بازی', child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.play_arrow_rounded, size: 31, color: light)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('شروع بازی', style: AppTheme.headingFont(size: 23, color: light)), Text('بازیکنان را انتخاب کن و وارد سناریو شو', style: TextStyle(color: light.withOpacity(.72), fontWeight: FontWeight.w600, fontSize: 12))])), Icon(Icons.arrow_back_rounded, color: light)]));
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap; final Color primary, light, dark, muted;
  const _SettingsButton({required this.onTap, required this.primary, required this.light, required this.dark, required this.muted});
  @override Widget build(BuildContext context) => Game3DSurface(onPressed: onTap, customColors: Game3DColors.fromColor(AppTheme.uiCard), depth: 5, borderRadius: BorderRadius.circular(19), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), semanticLabel: 'تنظیمات', child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: primary.withOpacity(.09), borderRadius: BorderRadius.circular(14), border: Border.all(color: primary.withOpacity(.16))), child: Icon(Icons.tune_rounded, color: primary, size: 24)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تنظیمات', style: AppTheme.headingFont(size: 21, color: light)), Text('ظاهر، تم و صدای بازی', style: TextStyle(color: muted, fontSize: 11))])), Icon(Icons.chevron_left_rounded, color: dark)]));
}

class _SectionTitle extends StatelessWidget {
  final String title; final Color primary;
  const _SectionTitle({required this.title, required this.primary});
  @override Widget build(BuildContext context) => Row(children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w800)), const SizedBox(width: 10), Expanded(child: Divider(color: primary.withOpacity(.13)))]);
}

class _HomeTile extends StatelessWidget {
  final String title, subtitle; final IconData icon; final VoidCallback onTap; final Color primary, dark, card, muted;
  const _HomeTile({required this.title, required this.subtitle, required this.icon, required this.onTap, required this.primary, required this.dark, required this.card, required this.muted});
  @override Widget build(BuildContext context) => Game3DSurface(onPressed: onTap, customColors: Game3DColors.fromColor(card), depth: 4, borderRadius: BorderRadius.circular(17), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), semanticLabel: title, child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: primary.withOpacity(.09), borderRadius: BorderRadius.circular(13), border: Border.all(color: primary.withOpacity(.16))), child: Icon(icon, color: primary, size: 22)), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 10.5))])), Icon(Icons.chevron_left_rounded, color: dark, size: 20)]));
}
