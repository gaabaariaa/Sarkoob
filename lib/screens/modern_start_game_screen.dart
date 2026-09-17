import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'modern_role_setup_screen.dart';
import 'roster_screen.dart';

/// لایه‌ی جدید شروع بازی؛ منطق سناریو و نقش‌ها در StartGameScreen اصلی
/// باقی می‌ماند تا رنگ‌ها و رفتار نقش‌ها/تیم‌ها تغییر نکند.
class ModernStartGameScreen extends StatefulWidget {
  const ModernStartGameScreen({super.key});

  @override
  State<ModernStartGameScreen> createState() => _ModernStartGameScreenState();
}

class _ModernStartGameScreenState extends State<ModernStartGameScreen> {
  final _controller = TextEditingController();
  final _players = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty || _players.contains(name)) return;
    setState(() {
      _players.add(name);
      _controller.clear();
    });
  }

  Future<void> _pickSavedPlayers() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => RosterScreen(selectionMode: true, initialSelection: _players)),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _players
        ..clear()
        ..addAll(selected);
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ModernRoleSetupScreen(players: List.unmodifiable(_players))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _players.length;
    final ready = total >= 9;
    return Scaffold(
      body: Stack(
        children: [
          const _StartAmbient(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 18, wide ? 36 : 18, 28),
                      children: [
                        _Header(onBack: () => Navigator.of(context).pop()),
                        const SizedBox(height: 18),
                        _Hero(total: total),
                        const SizedBox(height: 14),
                        _PlayerComposer(controller: _controller, onAdd: _addPlayer, onRoster: _pickSavedPlayers),
                        const SizedBox(height: 14),
                        if (_players.isEmpty)
                          const _EmptyPlayers()
                        else
                          _PlayerList(players: _players, onRemove: (index) => setState(() => _players.removeAt(index))),
                        const SizedBox(height: 14),
                        _StatusCard(total: total, ready: ready),
                        const SizedBox(height: 18),
                        Game3DButton(
                          label: ready ? 'ادامه و تنظیم نقش‌ها' : 'حداقل ۹ بازیکن لازم است',
                          icon: ready ? Icons.arrow_back_rounded : Icons.lock_outline_rounded,
                          onPressed: ready ? _continue : null,
                        ),
                        const SizedBox(height: 10),
                        Text('رنگ و هویت تیم‌ها و نقش‌ها در مرحله‌ی بعدی بدون تغییر باقی می‌ماند.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtleText)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StartAmbient extends StatelessWidget {
  const _StartAmbient();
  @override
  Widget build(BuildContext context) => Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: AppColors.background, gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 1.2, colors: [AppColors.gold.withOpacity(0.10), AppColors.background], stops: const [0, 0.7]))));
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_rounded), color: AppColors.goldLight),
    const SizedBox(width: 4),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('شروع بازی', style: AppTheme.headingFont(size: 26)), Text('میز بازی را آماده کن', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText))])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withOpacity(0.18))), child: Text('دست خدا', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w800))),
  ]);
}

class _Hero extends StatelessWidget {
  final int total;
  const _Hero({required this.total});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.surfaceElevated, AppColors.surfaceDark]), border: Border.fromBorderSide(BorderSide(color: AppColors.gold, width: 0.20)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 24, offset: const Offset(0, 12))]),
    child: Row(children: [
      Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.gold]), boxShadow: [BoxShadow(color: AppColors.gold, blurRadius: 22)]), child: const Icon(Icons.groups_rounded, color: Color(0xFF251A04), size: 31)),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('بازیکن‌های این میز', style: AppTheme.headingFont(size: 22)), const SizedBox(height: 3), Text(total == 0 ? 'بازیکن‌ها را اضافه کن تا میز آماده شود.' : '$total نفر برای بازی ثبت شده‌اند.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText))])),
      Text('$total', style: AppTheme.headingFont(size: 30)),
    ]),
  );
}

class _PlayerComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback onRoster;
  const _PlayerComposer({required this.controller, required this.onAdd, required this.onRoster});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    Row(children: [Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.done, onSubmitted: (_) => onAdd(), decoration: const InputDecoration(labelText: 'نام بازیکن', hintText: 'مثلاً علی', prefixIcon: Icon(Icons.person_add_alt_1_rounded)))), const SizedBox(width: 9), IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add_rounded), tooltip: 'افزودن')]),
    const SizedBox(height: 8),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onRoster, icon: const Icon(Icons.groups_rounded, size: 18), label: const Text('انتخاب از بازیکنان ذخیره‌شده'))),
  ])));
}

class _EmptyPlayers extends StatelessWidget {
  const _EmptyPlayers();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18), decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(0.65), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withOpacity(0.10))), child: Column(children: [const Icon(Icons.person_outline_rounded, size: 34, color: AppColors.subtleText), const SizedBox(height: 8), Text('هنوز بازیکنی اضافه نشده', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)), const SizedBox(height: 3), Text('از کادر بالا شروع کن.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.subtleText))]));
}

class _PlayerList extends StatelessWidget {
  final List<String> players;
  final ValueChanged<int> onRemove;
  const _PlayerList({required this.players, required this.onRemove});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('لیست بازیکنان', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w800)), const Spacer(), Text('${players.length} نفر', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.mutedText))]),
    const SizedBox(height: 8),
    ...players.asMap().entries.map((entry) => Container(margin: const EdgeInsets.only(bottom: 7), decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gold.withOpacity(0.08))), child: ListTile(dense: true, leading: CircleAvatar(radius: 17, backgroundColor: AppColors.gold.withOpacity(0.10), child: Text('${entry.key + 1}', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800))), title: Text(entry.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), trailing: IconButton(onPressed: () => onRemove(entry.key), icon: const Icon(Icons.close_rounded), color: AppColors.mutedText, tooltip: 'حذف')))),
  ])));
}

class _StatusCard extends StatelessWidget {
  final int total;
  final bool ready;
  const _StatusCard({required this.total, required this.ready});
  @override
  Widget build(BuildContext context) {
    final text = ready ? 'میز آماده‌ی تنظیم نقش‌هاست' : '${9 - total} نفر دیگر لازم است';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), decoration: BoxDecoration(color: (ready ? AppColors.gold : AppColors.bloodRedLight).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: (ready ? AppColors.gold : AppColors.bloodRedLight).withOpacity(0.20))), child: Row(children: [Icon(ready ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: ready ? AppColors.gold : AppColors.bloodRedLight), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))), if (ready) const Icon(Icons.arrow_back_rounded, color: AppColors.gold, size: 19)]));
  }
}
