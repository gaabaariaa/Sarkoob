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
  final String nextLabel;
  final String? eyebrow;

  const ModernSpeakingPanel({
    super.key,
    required this.speakerName,
    required this.remainingPlayers,
    required this.seconds,
    required this.challengeActive,
    required this.onNext,
    this.onFinishChallenge,
    this.onChooseChallenge,
    this.onTimerFinished,
    this.nextLabel = 'نفر بعدی',
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhaseHeader(eyebrow: eyebrow ?? 'نوبت صحبت'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(.34)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.30),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatusChip(icon: Icons.record_voice_over, text: 'در حال صحبت')),
                    const SizedBox(width: 8),
                    _StatusChip(
                      icon: challengeActive ? Icons.flash_on : Icons.groups,
                      text: challengeActive ? 'چالش فعال' : '$remainingPlayers نفر باقی',
                      active: challengeActive,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'نوبتِ',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  speakerName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                if (seconds != null)
                  CountdownTimerWidget(
                    key: ValueKey('speaking-timer-$speakerName-$seconds'),
                    totalSeconds: seconds!,
                    onFinished: onTimerFinished,
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(nextLabel),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    if (challengeActive && onFinishChallenge != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onFinishChallenge,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('پایان چالش'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: AppColors.goldLight,
                            side: BorderSide(color: AppColors.gold.withOpacity(.45)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onChooseChallenge != null) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onChooseChallenge,
                    icon: const Icon(Icons.bolt_outlined, size: 20),
                    label: const Text('انتخاب چالش'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.mutedText, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'گرداننده، وضعیت و زمان را از این پنل کنترل می‌کند.',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12.5, height: 1.4),
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
  const _PhaseHeader({required this.eyebrow});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 7,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: const TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              const Text('کنترل میز بازی', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
            ],
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;
  const _StatusChip({required this.icon, required this.text, this.active = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gold.withOpacity(.12) : Colors.white.withOpacity(.035),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.gold.withOpacity(.28) : Colors.white.withOpacity(.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.goldLight : AppColors.mutedText),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: active ? AppColors.goldLight : AppColors.mutedText, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}