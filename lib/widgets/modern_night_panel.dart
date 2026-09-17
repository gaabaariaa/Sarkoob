import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_3d_button.dart';

class ModernNightPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? playerName;
  final Widget body;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const ModernNightPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.playerName,
    this.icon = Icons.nightlight_round,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withOpacity(.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.goldDark.withOpacity(.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.goldLight, size: 22),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow, style: const TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                if (playerName != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.goldDark.withOpacity(.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        playerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(.20)),
            ),
            child: body,
          ),
          const SizedBox(height: 12),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: Game3DButton(
                label: actionLabel,
                icon: Icons.arrow_back_rounded,
                onPressed: onAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
