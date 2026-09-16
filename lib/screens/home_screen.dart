import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'history_screen.dart';
import 'roster_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'start_game_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const gold = Color(0xFFE2B65A);

  @override
  Widget build(BuildContext context) {
    final menu = <_Item>[
      _Item('شروع بازی', Icons.person_outline_rounded, () => _go(context, const StartGameScreen())),
      _Item('بازیکنان', Icons.groups_outlined, () => _go(context, const RosterScreen())),
      _Item('آمار', Icons.bar_chart_rounded, () => _go(context, const StatsScreen())),
      _Item('تاریخچه بازی ها', Icons.schedule_rounded, () => _go(context, const HistoryScreen())),
      _Item('قوانین', Icons.balance_outlined, () => _go(context, const RulesScreen())),
      _Item('تنظیمات', Icons.settings_outlined, () => _go(context, const SettingsScreen())),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: CustomPaint(
                painter: _FramePainter(),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(children: [
                    const _Hero(),
                    const SizedBox(height: 9),
                    const _Divider(),
                    const SizedBox(height: 15),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menu.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.08,
                      ),
                      itemBuilder: (_, i) => _Tile(item: menu[i]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  static void _go(BuildContext c, Widget page) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.72,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/home_reference.webp', fit: BoxFit.cover, alignment: const Alignment(0, -.28), filterQuality: FilterQuality.high),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, const Color(0xFF080808).withOpacity(.97)], stops: const [0, .57, 1]))),
        Positioned(left: 15, right: 15, bottom: 8, child: Row(children: [
          const Expanded(child: _Line()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('دست خدا', style: GoogleFonts.lalezar(fontSize: 27, height: 1, color: const Color(0xFFFFD980), shadows: const [Shadow(blurRadius: 8, color: Colors.black)]))),
          const Expanded(child: _Line()),
        ])),
      ]),
    ),
  );
}

class _Tile extends StatelessWidget {
  final _Item item;
  const _Tile({required this.item});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: HomeScreen.gold.withOpacity(.15),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF302B26), Color(0xFF181411), Color(0xFF0C0A09)]),
          border: Border.all(color: Color(0xFFE8C16A), width: 1.25),
          boxShadow: const [BoxShadow(color: Color(0x5529160A), blurRadius: 12, offset: Offset(0, 6)), BoxShadow(color: Color(0x55E5B85D), blurRadius: 7, spreadRadius: -4)],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _SheenPainter())),
          Center(child: Padding(padding: const EdgeInsets.all(7), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 86, height: 86, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB9904B), width: 1.1), boxShadow: const [BoxShadow(color: Color(0x66E8C16A), blurRadius: 10)]), child: Icon(item.icon, size: 42, color: const Color(0xFFECC76D))),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, child: Text(item.title, textDirection: TextDirection.rtl, style: GoogleFonts.lalezar(fontSize: 23, height: 1.05, color: const Color(0xFFF0CB75)))),
          ]))),
        ]),
      ),
    ),
  );
}

class _Item { final String title; final IconData icon; final VoidCallback onTap; const _Item(this.title, this.icon, this.onTap); }
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Row(children: [Expanded(child: _Line()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.auto_awesome, color: HomeScreen.gold, size: 30)), Expanded(child: _Line())]);
}
class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) => const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, HomeScreen.gold, Colors.transparent])), child: SizedBox(height: 1));
}
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF9C7537);
    c.drawRect(Rect.fromLTWH(5, 5, s.width - 10, s.height - 10), p);
    final o = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.15..color = const Color(0xFFC49A4B);
    for (final x in [7.0, s.width - 7.0]) for (final y in [7.0, s.height - 7.0]) {
      final sx = x < s.width / 2 ? 1 : -1; final sy = y < s.height / 2 ? 1 : -1;
      c.drawCircle(Offset(x, y), 3, o);
      c.drawArc(Rect.fromCenter(center: Offset(x + sx * 7, y + sy * 7), width: 25, height: 25), 0, 1.5, false, o);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _SheenPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final path = Path()..moveTo(s.width * .68, 0)..lineTo(s.width, 0)..lineTo(s.width, s.height * .52)..close();
    c.drawPath(path, Paint()..color = Colors.white.withOpacity(.045));
    c.drawRect(Offset.zero & s, Paint()..shader = const RadialGradient(center: Alignment.bottomRight, radius: .95, colors: [Color(0x662B0905), Colors.transparent]).createShader(Offset.zero & s));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
