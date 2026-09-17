import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'modern_role_setup_screen.dart';
import 'roster_screen.dart';

class ModernStartGameScreen extends StatefulWidget {
  const ModernStartGameScreen({super.key});
  @override
  State<ModernStartGameScreen> createState() => _ModernStartGameScreenState();
}

class _ModernStartGameScreenState extends State<ModernStartGameScreen> {
  final _controller = TextEditingController();
  final _players = <String>[];
  GameScenario _scenario = SarkoobScenarios.mafia;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty || _players.contains(name)) return;
    setState(() { _players.add(name); _controller.clear(); });
  }

  Future<void> _pickSavedPlayers() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => RosterScreen(selectionMode: true, initialSelection: _players)),
    );
    if (!mounted || selected == null) return;
    setState(() { _players..clear()..addAll(selected); });
  }

  void _reorderPlayers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final player = _players.removeAt(oldIndex);
      _players.insert(newIndex, player);
    });
  }

  void _continue() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModernRoleSetupScreen(players: List.unmodifiable(_players), scenario: _scenario),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    final total = _players.length;
    final ready = total >= 9;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          color: theme.background,
          gradient: RadialGradient(center: const Alignment(0, -.9), radius: 1.2,
            colors: [theme.accent.withOpacity(.10), theme.background], stops: const [0, .7]),
        ))),
        SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 940), child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 18, wide ? 36 : 18, 28),
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 18),
              _ScenarioSelector(value: _scenario, onChanged: (value) => setState(() => _scenario = value)),
              const SizedBox(height: 14),
              _Hero(total: total, scenario: _scenario),
              const SizedBox(height: 14),
              _PlayerComposer(controller: _controller, onAdd: _addPlayer, onRoster: _pickSavedPlayers),
              const SizedBox(height: 14),
              if (_players.isEmpty) const _EmptyPlayers() else _PlayerList(
                players: _players,
                onRemove: (index) => setState(() => _players.removeAt(index)),
                onReorder: _reorderPlayers,
              ),
              const SizedBox(height: 14),
              _StatusCard(total: total, ready: ready),
              const SizedBox(height: 18),
              Game3DButton(label: ready ? 'ادامه و تنظیم نقش‌ها' : 'حداقل ۹ بازیکن لازم است', icon: ready ? Icons.arrow_back_rounded : Icons.lock_outline_rounded, onPressed: ready ? _continue : null),
              const SizedBox(height: 10),
              Text('سناریوی انتخاب‌شده تعیین می‌کند چه تیم‌ها و نقش‌هایی در مرحله‌ی بعد نمایش داده شوند.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.subtleText)),
            ],
          )));
        }))
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Row(children: [
      IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_forward_rounded), color: t.accentLight),
      const SizedBox(width: 4),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('شروع بازی', style: AppTheme.headingFont(size: 26, color: t.accentLight)),
        Text('سناریو و میز بازی را آماده کن', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.mutedText)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: t.accent.withOpacity(.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: t.accent.withOpacity(.18))), child: Text('دست خدا', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.accentLight, fontWeight: FontWeight.w800))),
    ]);
  }
}

class _ScenarioSelector extends StatelessWidget {
  final GameScenario value;
  final ValueChanged<GameScenario> onChanged;
  const _ScenarioSelector({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('سناریوی بازی', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: t.accentLight, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('سناریو مستقل انتخاب کن؛ تیم‌ها و نقش‌ها از همان سناریو می‌آیند.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.mutedText)),
      const SizedBox(height: 10),
      DropdownButtonFormField<GameScenario>(
        value: value,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.theater_comedy_rounded), labelText: 'انتخاب سناریو'),
        dropdownColor: t.surfaceDark,
        items: SarkoobScenarios.all.map((scenario) => DropdownMenuItem<GameScenario>(value: scenario, child: Text('${scenario.emoji}  ${scenario.name}'))).toList(),
        onChanged: (scenario) { if (scenario != null) onChanged(scenario); },
      ),
      const SizedBox(height: 8),
      Text(value.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.mutedText, height: 1.5)),
    ])));
  }
}

class _Hero extends StatelessWidget {
  final int total;
  final GameScenario scenario;
  const _Hero({required this.total, required this.scenario});
  @override
  Widget build(BuildContext context) {
    final t = AppThemeExtension.of(context);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [t.surfaceElevated, t.surfaceDark]),
      border: Border.all(color: t.accent.withOpacity(.20)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.30), blurRadius: 24, offset: const Offset(0, 12))],
    ), child: Row(children: [
      Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [t.accentLight, t.accent]), boxShadow: [BoxShadow(color: t.accent.withOpacity(.55), blurRadius: 22)]), child: Text(scenario.emoji, style: const TextStyle(fontSize: 29))),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(scenario.name, style: AppTheme.headingFont(size: 22, color: t.accentLight)), const SizedBox(height: 3), Text(total == 0 ? 'بازیکن‌ها را اضافه کن تا میز آماده شود.' : '$total نفر برای بازی ثبت شده‌اند.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.mutedText))])),
      Text('$total', style: AppTheme.headingFont(size: 30, color: t.accentLight)),
    ]));
  }
}

class _PlayerComposer extends StatelessWidget {
  final TextEditingController controller; final VoidCallback onAdd; final VoidCallback onRoster;
  const _PlayerComposer({required this.controller, required this.onAdd, required this.onRoster});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    Row(children: [Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.done, onSubmitted: (_) => onAdd(), decoration: const InputDecoration(labelText: 'نام بازیکن', hintText: 'مثلاً علی', prefixIcon: Icon(Icons.person_add_alt_1_rounded)))), const SizedBox(width: 9), IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add_rounded), tooltip: 'افزودن')]),
    const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onRoster, icon: const Icon(Icons.groups_rounded, size: 18), label: const Text('انتخاب از بازیکنان ذخیره‌شده'))),
  ])));
}

class _EmptyPlayers extends StatelessWidget {
  const _EmptyPlayers();
  @override
  Widget build(BuildContext context) { final t = AppThemeExtension.of(context); return Container(padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18), decoration: BoxDecoration(color: t.surfaceDark.withOpacity(.65), borderRadius: BorderRadius.circular(20), border: Border.all(color: t.accent.withOpacity(.10))), child: Column(children: [Icon(Icons.person_outline_rounded, size: 34, color: t.subtleText), const SizedBox(height: 8), Text('هنوز بازیکنی اضافه نشده', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)), const SizedBox(height: 3), Text('از کادر بالا شروع کن.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.subtleText))])); }
}

class _PlayerList extends StatelessWidget {
  final List<String> players; final ValueChanged<int> onRemove; final void Function(int, int) onReorder;
  const _PlayerList({required this.players, required this.onRemove, required this.onReorder});
  @override
  Widget build(BuildContext context) { final t = AppThemeExtension.of(context); return Card(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('لیست بازیکنان', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: t.accentLight, fontWeight: FontWeight.w800)), const Spacer(), Text('برای تغییر ترتیب بکشید', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.subtleText)), const SizedBox(width: 8), Text('${players.length} نفر', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: t.mutedText))]),
    const SizedBox(height: 8), ReorderableListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), buildDefaultDragHandles: false, itemCount: players.length, onReorder: onReorder, proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 8, borderRadius: BorderRadius.circular(14), child: child), itemBuilder: (context, index) => Container(key: ValueKey(players[index]), margin: const EdgeInsets.only(bottom: 7), decoration: BoxDecoration(color: t.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.accent.withOpacity(.08))), child: ListTile(dense: true, leading: ReorderableDragStartListener(index: index, child: SizedBox(width: 34, child: Icon(Icons.drag_handle_rounded, color: t.accentLight))), title: Text(players[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), trailing: IconButton(onPressed: () => onRemove(index), icon: const Icon(Icons.close_rounded), color: t.mutedText, tooltip: 'حذف'))))
  ]))); }
}

class _StatusCard extends StatelessWidget {
  final int total; final bool ready;
  const _StatusCard({required this.total, required this.ready});
  @override
  Widget build(BuildContext context) { final t = AppThemeExtension.of(context); final color = ready ? t.accent : AppColors.bloodRedLight; final text = ready ? 'میز آماده‌ی تنظیم نقش‌هاست' : '${9 - total} نفر دیگر لازم است'; return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(.20))), child: Row(children: [Icon(ready ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: color), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))), if (ready) Icon(Icons.arrow_back_rounded, color: t.accent, size: 19)])); }
}
