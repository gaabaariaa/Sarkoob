import 'package:flutter/material.dart';
import '../controllers/game_flow_controller.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer_widget.dart';

class GameFlowScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;

  const GameFlowScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  late final GameFlowController controller;

  @override
  void initState() {
    super.initState();
    controller = GameFlowController(players: widget.players, settings: widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(controller))),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  String _titleFor(GameFlowController c) {
    switch (c.phase) {
      case GamePhaseType.introDay:
        return 'روز معارفه';
      case GamePhaseType.introNight:
        return 'شب معارفه';
      case GamePhaseType.day:
        return 'روز ${c.roundNumber}';
      case GamePhaseType.night:
        return 'شب ${c.roundNumber}';
    }
  }

  Widget _buildBody() {
    switch (controller.phase) {
      case GamePhaseType.introDay:
        return _buildSpeakingPhase(isIntro: true);
      case GamePhaseType.introNight:
        return _buildIntroNight();
      case GamePhaseType.day:
        if (controller.lastResolution != null) return _buildDayResolved();
        if (controller.isSecondVoteRound) return _buildVotePanel(isSecondRound: true);
        if (controller.inDefense) return _buildDefensePhase();
        if (controller.votingStarted) return _buildVotePanel(isSecondRound: false);
        if (controller.isSpeakingRoundDone) return _buildStartVoteButton();
        return _buildSpeakingPhase(isIntro: false);
      case GamePhaseType.night:
        return _buildNightPlaceholder();
    }
  }

  // ---------- روز معارفه / روزهای عادی: نوبت صحبت ----------

  Widget _buildSpeakingPhase({required bool isIntro}) {
    final speaker = controller.speakerForDisplay;
    final isChallenge = controller.activeChallengerId != null;

    if (speaker == null) {
      return isIntro ? _buildStartIntroNightButton() : _buildStartVoteButton();
    }

    return Column(
      children: [
        if (isIntro)
          const Text(
            'هر بازیکن به ترتیب، خودش رو معرفی می‌کنه.',
            style: TextStyle(color: Colors.white60),
          ),
        const SizedBox(height: 16),
        if (isChallenge)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bloodRed.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.bloodRedLight),
            ),
            child: const Text(
              '⚡ این یه چالشه؛ بعدش نوبتِ عادی ادامه پیدا می‌کنه.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        Text(
          speaker.name,
          style: AppTheme.headingFont(size: 30),
        ),
        const SizedBox(height: 16),
        CountdownTimerWidget(
          key: ValueKey('${speaker.id}-$isChallenge'),
          totalSeconds: controller.currentTurnSeconds,
          onFinished: () {
            if (isChallenge) {
              controller.finishChallenge();
            } else {
              controller.advanceSpeaker();
            }
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            if (isChallenge) {
              controller.finishChallenge();
            } else {
              controller.advanceSpeaker();
            }
          },
          child: Text(isChallenge ? 'پایان چالش' : 'نفر بعدی'),
        ),
        if (!isIntro && !isChallenge) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.challengeEligiblePlayers.isEmpty
                ? null
                : () => _showChallengePicker(),
            icon: const Icon(Icons.bolt),
            label: const Text('چالش گرفتن یه بازیکن دیگه'),
          ),
        ],
        const Spacer(),
        Text(
          'ترتیب باقی‌مانده: ${controller.alivePlayers.where((p) => !p.hasSpokenThisRound).length} نفر',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  void _showChallengePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'کدوم بازیکن چالش می‌گیره؟',
                style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
            ...controller.challengeEligiblePlayers.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.useChallenge(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartVoteButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('همه صحبت کردن.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.startVoting,
            child: const Text('شروع رأی‌گیری'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartIntroNightButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('همه معارفه کردن.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.moveToIntroNight,
            child: const Text('ادامه به شب معارفه'),
          ),
        ],
      ),
    );
  }

  // ---------- شب معارفه ----------

  Widget _buildIntroNight() {
    final sorkoobExceptModiri =
        controller.players.where((p) => p.isSorkoobTeam && !p.isModiri).toList();
    return Column(
      children: [
        const Text(
          'فقط این افراد بیدار می‌شن، همدیگه رو می‌بینن و نقشه می‌کشن:',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: sorkoobExceptModiri
                .map(
                  (p) => Card(
                    color: AppColors.bloodRed.withOpacity(0.35),
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        ElevatedButton(
          onPressed: () => controller.moveToDay(1),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('ادامه به روز اول'),
        ),
      ],
    );
  }

  // ---------- رأی‌گیری (دور اول یا دوم) ----------

  Widget _buildVotePanel({required bool isSecondRound}) {
    final candidates = isSecondRound ? controller.defenseCandidates : controller.alivePlayers;
    return Column(
      children: [
        Text(
          isSecondRound ? 'رأی‌گیری نهایی (فقط بین نفرات دفاعیه)' : 'رأی‌گیری',
          style: AppTheme.headingFont(size: 20),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: candidates.map((p) => _voteRow(p)).toList(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (isSecondRound) {
              controller.resolveSecondVoteRound();
            } else {
              controller.resolveFirstVoteRound();
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(isSecondRound ? 'نهایی کردن نتیجه' : 'محاسبه‌ی نتیجه'),
        ),
      ],
    );
  }

  Widget _voteRow(SessionPlayer p) {
    return Card(
      color: AppColors.surfaceCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.gold),
              onPressed: () => controller.removeVote(p.id),
            ),
            Text('${p.votes}', style: const TextStyle(color: AppColors.goldLight, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              onPressed: () => controller.addVote(p.id),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- دفاعیه ----------

  Widget _buildDefensePhase() {
    final speaker = controller.currentDefenseSpeaker;
    if (speaker == null) {
      return Center(
        child: ElevatedButton(
          onPressed: controller.startSecondVoteRound,
          child: const Text('شروع رأی‌گیری نهایی'),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('در حال دفاعیه:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(speaker.name, style: AppTheme.headingFont(size: 28)),
        const SizedBox(height: 16),
        CountdownTimerWidget(
          key: ValueKey('defense-${speaker.id}'),
          totalSeconds: widget.settings.speakSeconds,
          onFinished: controller.advanceDefenseSpeaker,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: controller.advanceDefenseSpeaker,
          child: const Text('پایان دفاعیه‌ی این نفر'),
        ),
      ],
    );
  }

  // ---------- نتیجه‌ی روز ----------

  Widget _buildDayResolved() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gavel, size: 48, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            controller.lastResolution?.message ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.moveToNight(controller.roundNumber),
            child: const Text('ورود به شب'),
          ),
        ],
      ),
    );
  }

  // ---------- شب (بعد از معارفه) ----------

  Widget _buildNightPlaceholder() {
    if (controller.lastNightSummary != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nightlight_round, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              controller.lastNightSummary!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.moveToDay(controller.roundNumber + 1),
              child: Text('ادامه به روز ${controller.roundNumber + 1}'),
            ),
          ],
        ),
      );
    }

    final leader = controller.valiFaghihPlayer;
    if (leader == null || !leader.isAlive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ولی‌فقیه در بازی نیست یا حذف شده؛ این شب اقدامی ثبت نمی‌شه.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.finishNight,
              child: const Text('پایان شب'),
            ),
          ],
        ),
      );
    }

    if (!controller.nightActionTaken) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('شب ${controller.roundNumber}', style: AppTheme.headingFont(size: 24)),
          const SizedBox(height: 4),
          const Text(
            'تیم سرکوب بیدار می‌شه و باهم مشورت می‌کنن؛ تصمیم نهایی با ولی‌فقیه‌ست.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.gps_fixed),
            label: const Text('شات (حذف تیمی)'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => _showShootPicker(leader),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.content_cut),
            label: Text(
              'سلاخی (${leader.slaughterChargesRemaining ?? 0} باقیمانده)',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.bloodRedLight,
            ),
            onPressed: (leader.slaughterChargesRemaining ?? 0) > 0
                ? () => _showSlaughterPicker(leader)
                : null,
          ),
          if (controller.canUseNegotiate) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.handshake),
              label: const Text('مذاکره (اغفال شهروند خاکستری)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.goldDark,
              ),
              onPressed: () => _showNegotiatePicker(),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (controller.slaughterResultMessage != null) ...[
            Text(
              controller.slaughterResultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
          ] else if (controller.negotiateResultMessage != null) ...[
            Text(
              controller.negotiateResultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
          ] else
            const Text('تصمیمِ امشب ثبت شد.', style: TextStyle(color: Colors.white70)),
          ElevatedButton(
            onPressed: controller.finishNight,
            child: const Text('پایان شب'),
          ),
        ],
      ),
    );
  }

  void _showShootPicker(SessionPlayer leader) {
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('شات روی کی؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.leaderShoot(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNegotiatePicker() {
    final minister = controller.foreignMinisterPlayer;
    final targets = controller.alivePlayers
        .where((p) => minister == null || p.id != minister.id)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'با کی می‌خوان مذاکره کنن؟',
                style: TextStyle(color: AppColors.goldLight),
              ),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.leaderNegotiate(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlaughterPicker(SessionPlayer leader) {
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    SessionPlayer? selectedTarget;
    String? selectedRoleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('سلاخی: هدف + حدسِ نقش', style: TextStyle(color: AppColors.goldLight)),
                    const SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: const Text('انتخاب هدف', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: const Text('حدسِ نقش', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedRoleId,
                      items: SarkoobRoles.all
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.leaderSlaughter(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('تایید سلاخی'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
