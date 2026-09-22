import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'countdown_timer_widget.dart';

/// Presentation-only panel for the moderator speaking phase.
/// Game state and callbacks stay owned by GameFlowScreen.
class ModernSpeakingPanel extends StatelessWidget {
  final String speakerName;
  final int remainingPlayers;
  final int? seconds;
  final bool challengeActive;
  final VoidCallback onNext;
  final VoidCallback? onFinishChallenge;
  final VoidCallback? onChooseChallenge;
  final VoidCallback? onTimerFinished;
  final VoidCallback? onSecondElapsed;
  final String nextLabel;
  final String? eyebrow;

  ModernSpeakingPanel({
    super.key,
    required this.speakerName,
    required this.remainingPlayers,
    required this.seconds,
    required this.challengeActive,
    required this.onNext,
    this.onFinishChallenge,
    this.onChooseChallenge,
    this.onTimerFinished,
    this.onSecondElapsed,
    this.nextLabel = 'نفر بعدی',
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(2, 4, 2, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhaseHeader(eyebrow: eyebrow ?? 'نوبت صحبت'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(87)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatusChip(icon: Icons.record_voice_over, text: 'در حال صحبت')),
                    SizedBox(width: 8),
                    _StatusChip(
                      icon: challengeActive ? Icons.flash_on : Icons.groups,
                      text: challengeActive ? 'چالش فعال' : '$remainingPlayers نفر باقی',
                      active: challengeActive,
                    ),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  'نوبتِ',
                  style: TextStyle(color: AppTheme.uiMutedText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  speakerName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 20),
                if (seconds != null)
                  CountdownTimerWidget(
                    // Timer state must survive parent rebuilds while the countdown ticks.
                    // The parent already has a stable key per speaker/challenge turn;
                    // including `seconds` here would recreate the timer every second.
                    totalSeconds: seconds!,
                    onFinished: onTimerFinished,
                    onSecondElapsed: onSecondElapsed,
                  ),
                SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onNext,
                        icon: Icon(Icons.arrow_back_rounded),
                        label: Text(nextLabel),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(52),
                          backgroundColor: AppTheme.uiPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    if (challengeActive && onFinishChallenge != null) ...[
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onFinishChallenge,
                          icon: Icon(Icons.stop_circle_outlined),
                          label: Text('پایان چالش'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(52),
                            foregroundColor: AppTheme.uiPrimaryLight,
                            side: BorderSide(color: AppTheme.uiPrimary.withAlpha(115)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onChooseChallenge != null) ...[
                  SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onChooseChallenge,
                    icon: Icon(Icons.bolt_outlined, size: 20),
                    label: Text('انتخاب چالش'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.uiPrimaryLight),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.uiSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.uiMutedText, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'گرداننده، وضعیت و زمان را از این پنل کنترل می‌کند.',
                    style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final String eyebrow;
  _PhaseHeader({required this.eyebrow});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 7,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.uiPrimary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text('کنترل میز بازی', style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
            ],
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;
  _StatusChip({required this.icon, required this.text, this.active = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.uiPrimary.withAlpha(31) : Colors.white.withAlpha(9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.uiPrimary.withAlpha(71) : Colors.white.withAlpha(15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppTheme.uiPrimaryLight : AppTheme.uiMutedText),
            SizedBox(width: 6),
            Text(text, style: TextStyle(color: active ? AppTheme.uiPrimaryLight : AppTheme.uiMutedText, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}