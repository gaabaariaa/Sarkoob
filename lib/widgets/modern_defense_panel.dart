import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'countdown_timer_widget.dart';
import 'game_3d_button.dart';

class ModernDefensePanel extends StatelessWidget {
  final String speakerName;
  final int currentIndex;
  final int totalCandidates;
  final int seconds;
  final VoidCallback onNext;
  final VoidCallback onTimerFinished;
  final String? teamLabel;

  const ModernDefensePanel({
    super.key,
    required this.speakerName,
    required this.currentIndex,
    required this.totalCandidates,
    required this.seconds,
    required this.onNext,
    required this.onTimerFinished,
    this.teamLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCandidates <= 0
        ? 0.0
        : (currentIndex / totalCandidates).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.bloodRed.withOpacity(0.28),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.bloodRedLight.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.bloodRedLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, color: AppColors.goldLight),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('فاز دفاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('هر بازیکن فرصت دفاع از خودش را دارد.', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
                Text('$currentIndex / $totalCandidates', style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(0.28)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('نوبت دفاع', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(speakerName, textAlign: TextAlign.center, style: AppTheme.headingFont(size: 28)),
                if (teamLabel != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.goldDark.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                    child: Text(teamLabel!, style: const TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 18),
                CountdownTimerWidget(
                  key: ValueKey('modern-defense-$speakerName-$currentIndex'),
                  totalSeconds: seconds,
                  onFinished: onTimerFinished,
                ),
                const SizedBox(height: 18),
                Text(
                  'صحبتت را کامل کن؛ بعد از پایان دفاع، نوبت نفر بعدی می‌رسد.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Game3DButton(
              label: 'پایان دفاع و نفر بعدی',
              icon: Icons.arrow_back_rounded,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
