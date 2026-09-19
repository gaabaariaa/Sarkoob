import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/role_scoring_info.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';

class RoleInfoCard extends StatelessWidget {
  final GameRole role;
  final GameTeam team;
  final bool showScoringInfo;

  const RoleInfoCard({
    super.key,
    required this.role,
    required this.team,
    this.showScoringInfo = false,
  });

  GameScenario get _scenarioForTeam => SarkoobScenarios.byId(team.scenarioId) ??
      (throw StateError('Unknown scenario "${team.scenarioId}" for team ${team.id}'));

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _panel(
            borderColor: team.color.withAlpha(140),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 42,
                  decoration: BoxDecoration(
                    color: team.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.name,
                    style: TextStyle(
                      color: team.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                Icon(Icons.groups_rounded, color: team.color, size: 23),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: team.color.withAlpha(71)),
            ),
            clipBehavior: Clip.antiAlias,
            child: role.imageAsset != null
                ? AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      role.imageAsset!,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  )
                : SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(Icons.badge_rounded, size: 64, color: team.color),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          _panel(
            borderColor: AppColors.gold.withAlpha(56),
            child: Center(
              child: Text(role.name, style: AppTheme.headingFont(size: 23)),
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            color: AppColors.surfaceDark,
            borderColor: Colors.transparent,
            child: Text(
              role.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.7, fontSize: 13),
            ),
          ),
          if (showScoringInfo && roleScoringInfoForScenario(_scenarioForTeam).containsKey(role.id)) ...[
            const SizedBox(height: 14),
            _panel(
              borderColor: AppColors.gold.withAlpha(71),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.goldLight, size: 20),
                      const SizedBox(width: 8),
                      Text('امتیازدهی', style: AppTheme.headingFont(size: 17)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    roleScoringInfoForScenario(_scenarioForTeam)[role.id]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, height: 1.7, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
    Color? color,
    Color borderColor = AppColors.gold,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
