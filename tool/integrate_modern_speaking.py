from pathlib import Path

path = Path('lib/screens/game_flow_screen.dart')
text = path.read_text(encoding='utf-8')

start_marker = '  Widget _buildSpeakingPhase({required bool isIntro}) {'
end_marker = '  /// جعبه‌ابزارِ مشترکِ همه‌ی «انتخابِ یه بازیکن از لیست»'

start = text.index(start_marker)
end = text.index(end_marker, start)

if 'ModernSpeakingPanel(' in text[start:end]:
    print('ModernSpeakingPanel is already integrated.')
    raise SystemExit(0)

replacement = '''  Widget _buildSpeakingPhase({required bool isIntro}) {
    final speaker = controller.speakerForDisplay;
    final isChallenge = controller.activeChallengerId != null;

    if (speaker == null) {
      return isIntro ? _buildStartIntroNightButton() : _buildStartVoteButton();
    }

    final banners = <Widget>[];

    if (!isIntro && controller.guaranteedPlayerId != null) {
      banners.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.goldDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🛡️ «${controller.playerById(controller.guaranteedPlayerId!).name}» تضمینِ ${SarkoobRoles.byId(controller.playerById(controller.guaranteedPlayerId!).roleId!)?.name ?? "قهرمانِ ملی"} رو داره؛ امروز نمی‌تونه رأی بیاره و در امانه.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
        ),
      ));
    }

    if (!isIntro && controller.referendumScheduledToday) {
      banners.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.goldDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '🗳️ امروز، درست قبل از شروعِ رأی‌گیریِ حذف، رفراندومِ انتخابِ رهبرِ جامعه برگزار می‌شه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
        ),
      ));
    }

    if (!isIntro && controller.assassinationResultMessage != null) {
      banners.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          controller.assassinationResultMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
        ),
      ));
    }

    if (!isIntro && controller.gunFireResultMessage != null) {
      banners.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          controller.gunFireResultMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
        ),
      ));
    }

    if (!isIntro && controller.armedPlayers.isNotEmpty) banners.add(_buildGunBanner());
    if (!isIntro && controller.canAssassinateNow) banners.add(_buildMercenaryDayBanner());
    if (!isIntro && controller.bombTargetId != null && !controller.bombFullyResolved) {
      banners.add(_buildBombDayBanner());
    }
    if (!isIntro && controller.activeExecutionWord != null) {
      banners.add(_buildExecutionWordBanner());
    }

    if (isIntro) {
      banners.add(const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'هر بازیکن به ترتیب، خودش رو معرفی می‌کنه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...banners,
        ModernSpeakingPanel(
          key: ValueKey('${speaker.id}-$isChallenge'),
          speakerName: speaker.name,
          remainingPlayers: controller.alivePlayers.where((p) => !p.hasSpokenThisRound).length,
          seconds: controller.currentTurnSeconds,
          challengeActive: isChallenge,
          eyebrow: isIntro ? 'روزِ معارفه' : 'نوبتِ صحبت',
          nextLabel: isChallenge ? 'ادامه نوبت' : 'نفر بعدی',
          onNext: () {
            MusicService.instance.stopAlert();
            if (isChallenge) {
              controller.finishChallenge();
            } else {
              controller.advanceSpeaker();
            }
          },
          onFinishChallenge: isChallenge
              ? () {
                  MusicService.instance.stopAlert();
                  controller.finishChallenge();
                }
              : null,
          onChooseChallenge: (!isIntro &&
                  controller.challengeEligiblePlayers.isNotEmpty &&
                  controller.canCurrentSpeakerGiveChallenge)
              ? () {
                  MusicService.instance.stopAlert();
                  _showChallengePicker();
                }
              : null,
        ),
        if (!isIntro && controller.todaysChallenges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'چالش‌های امروز:\n${controller.todaysChallenges.map((c) => '${controller.playerById(c.giverId).name} ← چالش داد به → ${controller.playerById(c.receiverId).name}').join('\n')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }

'''

path.write_text(text[:start] + replacement + text[end:], encoding='utf-8')
print('ModernSpeakingPanel integration applied.')
