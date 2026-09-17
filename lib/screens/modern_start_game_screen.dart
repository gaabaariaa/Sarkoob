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
  final List<String> _players = [];
  GameScenario _scenario = SarkoobScenarios.mafia;

  void _continue() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModernRoleSetupScreen(
        players: List.unmodifiable(_players),
        scenario: _scenario,
      ),
    ));
  }

  Future<void> _pickSavedPlayers() async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => RosterScreen(selectionMode: true, initialSelection: _players)),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _players..clear()..addAll(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _players.isNotEmpty;
    return Scaffold(
      body: Stack(children: [
        const _Ambient(),
        SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('شروع بازی', style: AppTheme.headingFont(size: 28)),
            const SizedBox(height: 4),
            const Text('میز بازی را آماده کن', style: TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 22),
            _SectionCard(
              title: 'سناریوی بازی',
              child: DropdownButtonFormField<GameScenario>(
                value: _scenario,
                dropdownColor: AppColors.surfaceCard,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.auto_awesome_rounded), border: OutlineInputBorder()),
                items: SarkoobScenarios.all.map((scenario) => DropdownMenuItem(value: scenario, child: Text('${scenario.emoji}  ${scenario.name}'))).toList(),
                onChanged: (value) { if (value != null) setState(() => _scenario = value); },
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'بازیکنان',
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text('${_players.length} بازیکن انتخاب شده', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  TextButton.icon(onPressed: _pickSavedPlayers, icon: const Icon(Icons.people_alt_rounded), label: const Text('انتخاب از فهرست')),
                ]),
                if (_players.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._players.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 15, child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  )),
                ] else
                  const Padding(padding: EdgeInsets.all(12), child: Text('بازیکنان را از فهرست انتخاب کن.', style: TextStyle(color: AppColors.mutedText))),
              ]),
            ),
            const SizedBox(height: 22),
            Game3DButton(label: 'ادامه با ${_scenario.name}', icon: Icons.arrow_back_rounded, onPressed: ready ? _continue : null),
          ]),
        )))
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.gold.withOpacity(.16))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.headingFont(size: 18)), const SizedBox(height: 12), child]),
  );
}

class _Ambient extends StatelessWidget {
  const _Ambient();
  @override
  Widget build(BuildContext context) => Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: AppColors.background, gradient: RadialGradient(center: const Alignment(0, -.8), radius: 1.2, colors: [AppColors.gold.withOpacity(.08), AppColors.background], stops: const [0, .72]))));
}
