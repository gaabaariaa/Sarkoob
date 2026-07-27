import 'package:flutter/material.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';

/// کارتی که بازیکن روی اسمش می‌زنه تا (فعلاً) تیمش رو ببینه.
class TeamRevealCard extends StatefulWidget {
  final GameTeam team;
  final String playerName;

  const TeamRevealCard({
    super.key,
    required this.team,
    required this.playerName,
  });

  @override
  State<TeamRevealCard> createState() => _TeamRevealCardState();
}

class _TeamRevealCardState extends State<TeamRevealCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 260,
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.6),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _revealed
                ? [widget.team.color.withOpacity(0.9), AppColors.background]
                : [AppColors.surfaceCard, AppColors.background],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.25),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _revealed ? _buildRevealedContent() : _buildHiddenContent(),
        ),
      ),
    );
  }

  Widget _buildHiddenContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.help_outline, size: 60, color: AppColors.gold),
        const SizedBox(height: 18),
        Text(
          widget.playerName,
          style: const TextStyle(
            color: AppColors.goldLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'برای دیدن تیم لمس کن',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRevealedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security, size: 56, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          widget.team.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.team.description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
      ],
    );
  }
}
