import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_3d_button.dart';
import 'countdown_timer_widget.dart';

class ModernNightPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? playerName;
  final Widget body;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final IconData actionIcon;
  /// زمان اختصاصی هر اکشن شب؛ در صورت null تایمر نمایش داده نمی‌شود.
  final int? timerSeconds;
  final String? timerKey;

  ModernNightPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.playerName,
    this.icon = Icons.nightlight_round,
    this.actionIcon = Icons.arrow_back_rounded,
    this.timerSeconds,
    this.timerKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.uiSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.uiPrimaryDark.withAlpha(56),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.uiPrimaryLight, size: 22),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow, style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 11, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                if (playerName != null)
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.uiPrimaryDark.withAlpha(46),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        playerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(51)),
            ),
            child: body,
          ),
          if (timerSeconds != null) ...[
            SizedBox(height: 12),
            CountdownTimerWidget(
              key: timerKey == null ? null : ValueKey(timerKey),
              totalSeconds: timerSeconds!,
              label: 'زمانِ اکشن شب',
            ),
          ],
          SizedBox(height: 12),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: Game3DButton(
                label: actionLabel,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
