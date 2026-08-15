import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../widgets/ornate_frame.dart';
import '../widgets/role_card.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  GameScenario _selectedScenario = SarkoobScenarios.sorkoob;

  @override
  Widget build(BuildContext context) {
    final teams = SarkoobTeams.selectableForScenario(_selectedScenario.id);

    return Scaffold(
      appBar: AppBar(title: Text('قوانین — سناریوی ${_selectedScenario.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<GameScenario>(
              segments: SarkoobScenarios.all
                  .map(
                    (s) => ButtonSegment<GameScenario>(
                      value: s,
                      label: Text('${s.emoji} ${s.name}'),
                    ),
                  )
                  .toList(),
              selected: {_selectedScenario},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedScenario = selection.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: teams.map((team) {
                final roles = SarkoobRoles.forTeam(team.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: OrnateFrame(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            team.name,
                            style: AppTheme.headingFont(size: 22, color: team.color),
                          ),
                          const SizedBox(height: 8),
                          ...roles.map((role) => RoleCard(role: role)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
