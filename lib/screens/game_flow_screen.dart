import 'package:flutter/material.dart';
import '../controllers/game_flow_controller.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/role_card.dart';

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
        return _buildNightPhase();
    }
  }

  // ---------- روز معارفه / روزهای عادی: نوبت صحبت ----------

  Widget _buildSpeakingPhase({required bool isIntro}) {
    final speaker = controller.speakerForDisplay;
    final isChallenge = controller.activeChallengerId != null;

    if (speaker == null) {
      return isIntro ? _buildStartIntroNightButton() : _buildStartVoteButton();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (!isIntro && controller.gunFireResultMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.gunFireResultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.armedPlayers.isNotEmpty) _buildGunBanner(),
          if (!isIntro && controller.activeExecutionWord != null) _buildExecutionWordBanner(),
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
          const SizedBox(height: 16),
          Text(
            'ترتیب باقی‌مانده: ${controller.alivePlayers.where((p) => !p.hasSpokenThisRound).length} نفر',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
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
          if (controller.gunFireResultMessage != null) ...[
            Text(
              controller.gunFireResultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.armedPlayers.isNotEmpty) ...[
            _buildGunBanner(),
            const SizedBox(height: 12),
          ],
          if (controller.activeExecutionWord != null) ...[
            _buildExecutionWordBanner(),
            const SizedBox(height: 12),
          ],
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

  Widget _buildGunBanner() {
    final armed = controller.armedPlayers;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Column(
        children: [
          const Text(
            '🔫 یکی از بازیکن‌ها الان اسلحه داره و می‌تونه اعلامِ اسلحه کنه',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '(کسایی که اسلحه دارن: ${armed.map((p) => p.name).join('، ')})',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showFireGunDialog,
            child: const Text('اعلامِ اسلحه و شلیک'),
          ),
        ],
      ),
    );
  }

  void _showFireGunDialog() {
    final shooters = controller.armedPlayers;
    SessionPlayer? selectedShooter;
    SessionPlayer? selectedTarget;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final targets =
              controller.alivePlayers.where((p) => p.id != selectedShooter?.id).toList();
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('اعلامِ اسلحه', style: TextStyle(color: AppColors.goldLight)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<SessionPlayer>(
                  isExpanded: true,
                  hint: const Text('کی اعلامِ اسلحه می‌کنه؟', style: TextStyle(color: Colors.white70)),
                  dropdownColor: AppColors.surfaceDark,
                  value: selectedShooter,
                  items: shooters
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedShooter = v;
                    selectedTarget = null;
                  }),
                ),
                const SizedBox(height: 8),
                DropdownButton<SessionPlayer>(
                  isExpanded: true,
                  hint: const Text('روی کی شلیک کنه؟', style: TextStyle(color: Colors.white70)),
                  dropdownColor: AppColors.surfaceDark,
                  value: selectedTarget,
                  items: targets
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedTarget = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: (selectedShooter != null && selectedTarget != null)
                    ? () {
                        controller.fireGun(selectedShooter!.id, selectedTarget!.id);
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
                child: const Text('شلیک'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutionWordBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Column(
        children: [
          Text(
            '⚖️ حکم اعدام صادر شده؛ کلمه‌ی ممنوع: «${controller.activeExecutionWord}»',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showForbiddenWordPicker,
            child: const Text('یکی این کلمه رو گفت!'),
          ),
        ],
      ),
    );
  }

  void _showForbiddenWordPicker() {
    final targets = controller.alivePlayers;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('کی این کلمه رو گفت؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.executePlayerForForbiddenWord(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
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
        if (!isSecondRound && controller.gunExplosionSummary != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.gunExplosionSummary!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.bloodRedLight),
          ),
        ],
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

  Widget _buildNightPhase() {
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

    switch (controller.currentNightStep) {
      case NightStepKind.sorkoobTeam:
        return _buildSorkoobTeamStep();
      case NightStepKind.rapper:
        return _buildRoleNightStep(
          wakeLabel: 'رپر معترض بیدار بشه',
          sleepLabel: 'رپر معترض چشمش رو ببنده',
          body: _buildRapperSection(),
        );
      case NightStepKind.hacker:
        return _buildRoleNightStep(
          wakeLabel: 'هکر بیدار بشه',
          sleepLabel: 'هکر چشمش رو ببنده',
          body: _buildHackerSection(),
        );
      case NightStepKind.doctor:
        return _buildRoleNightStep(
          wakeLabel: 'دکتر بیدار بشه',
          sleepLabel: 'دکتر چشمش رو ببنده',
          body: _buildDoctorSection(),
        );
      case NightStepKind.rebel:
        return _buildRoleNightStep(
          wakeLabel: 'شورشی بیدار بشه',
          sleepLabel: 'شورشی چشمش رو ببنده',
          body: _buildRebelSection(),
        );
      case NightStepKind.revolutionary:
        return _buildRoleNightStep(
          wakeLabel: 'مبارز انقلابی بیدار بشه',
          sleepLabel: 'مبارز انقلابی چشمش رو ببنده',
          body: _buildRevolutionarySection(),
        );
      case NightStepKind.lawyer:
        return _buildRoleNightStep(
          wakeLabel: 'وکیل بیدار بشه',
          sleepLabel: 'وکیل چشمش رو ببنده',
          body: _buildLawyerSection(),
        );
      case NightStepKind.done:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'همه‌ی نقش‌ها اقدامِ امشب‌شون رو انجام دادن.',
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
  }

  /// مرحله‌ی مشترکِ «تیمِ سرکوب بیدار می‌شه»: تصمیمِ ولی‌فقیه + مذاکره‌ی وزیر
  /// امور خارجه + حکمِ اعدامِ رئیس قوه قضاییه، چون هر سه عضوِ همین تیم‌ان.
  Widget _buildSorkoobTeamStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('شب ${controller.roundNumber}', style: AppTheme.headingFont(size: 24)),
          const SizedBox(height: 8),
          const Text(
            '🔴 اعضای تیم سرکوب بیدار بشن',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (controller.sorkoobDisabledTonight)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'امشب (به‌خاطرِ حذف‌شدنِ ژینا دیشب) تیمِ سرکوب هیچ قابلیتی '
                'نداره — فقط برو به مرحله‌ی بعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          else ...[
            _buildLeaderDecisionSection(),
            if (controller.canIssueExecutionOrder) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildJudiciarySection(),
            ],
            if (controller.interrogatorPlayer != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildInterrogatorSection(),
            ],
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: controller.canAdvancePastSorkoobTeamStep ? controller.advanceNightStep : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('🌑 اعضای تیم سرکوب چشم‌هاشون رو ببندن'),
          ),
        ],
      ),
    );
  }

  /// مرحله‌ی مشترکِ هر نقشِ خاصِ شهروندی که تنها و جداگونه بیدار می‌شه.
  Widget _buildRoleNightStep({
    required String wakeLabel,
    required String sleepLabel,
    required Widget body,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            '🔓 $wakeLabel',
            textAlign: TextAlign.center,
            style: AppTheme.headingFont(size: 22),
          ),
          const SizedBox(height: 16),
          body,
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: controller.advanceNightStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text('🌑 $sleepLabel'),
          ),
        ],
      ),
    );
  }

  Widget _buildRapperSection() {
    final rapper = controller.rapperPlayer!;
    final result = controller.rapperResultMessage;
    final resistance = controller.activeResistanceMembers;
    return Column(
      children: [
        const Text(
          'رپر معترض می‌تونه امشب یه نفر رو برای عضوگیری تو مقاومت انتخاب کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (result != null) ...[
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (resistance.isNotEmpty)
            Text(
              'حالا بگو: اعضای مقاومتِ فعال (${resistance.map((p) => p.name).join('، ')}) بیدار بشن '
              'تا وضعیتِ جدید رو ببینن.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.groups),
          label: const Text('انتخابِ یه بازیکن'),
          onPressed: controller.canRapperActTonight ? () => _showRapperPicker(rapper) : null,
        ),
      ],
    );
  }

  void _showRapperPicker(SessionPlayer rapper) {
    final targets = controller.alivePlayers.where((p) => p.id != rapper.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('کی رو برای مقاومت انتخاب کنه؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.rapperRecruit(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderDecisionSection() {
    final leader = controller.valiFaghihPlayer;
    final leaderAlive = leader != null && leader.isAlive;

    if (!controller.nightActionTaken) {
      return Column(
        children: [
          Text(
            leaderAlive
                ? 'تیم سرکوب بیدار می‌شه و باهم مشورت می‌کنن؛ تصمیم نهایی با ولی‌فقیه‌ست.'
                : 'ولی‌فقیه در بازی نیست یا حذف شده؛ شات و سلاخیِ رهبر دیگه در دسترس نیست.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          if (leaderAlive) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.gps_fixed),
              label: const Text('شات (حذف تیمی)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => _showShootPicker(leader),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.content_cut),
              label: Text('سلاخی (${leader.slaughterChargesRemaining ?? 0} باقیمانده)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.bloodRedLight,
              ),
              onPressed: (leader.slaughterChargesRemaining ?? 0) > 0
                  ? () => _showSlaughterPicker(leader)
                  : null,
            ),
          ],
          // نکته‌ی مهم: این شرط از رویِ زنده‌بودنِ ولی‌فقیه مستقل بررسی
          // می‌شه، چون قابلیتِ مذاکره‌ی وزیر امور خارجه به رهبر ربطی نداره
          // و حتی بعدِ حذفِ ولی‌فقیه هم باید در دسترس بمونه.
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

    return Column(
      children: [
        if (controller.slaughterResultMessage != null)
          Text(
            controller.slaughterResultMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
        else if (controller.negotiateResultMessage != null)
          Text(
            controller.negotiateResultMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
        else
          const Text('تصمیمِ امشب ثبت شد.', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildJudiciarySection() {
    return Column(
      children: [
        const Text(
          'رئیس قوه قضاییه می‌تونه (فقط یک‌بار در کل بازی) حکم اعدام صادر کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.gavel),
          label: const Text('صدور حکم اعدام'),
          onPressed: _showExecutionWordDialog,
        ),
      ],
    );
  }

  void _showExecutionWordDialog() {
    final wordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('کلمه‌ی حکم اعدام', style: TextStyle(color: AppColors.goldLight)),
        content: TextField(
          controller: wordController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'کلمه رو وارد کن'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wordController.text.trim().isNotEmpty) {
                controller.issueExecutionOrder(wordController.text);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterrogatorSection() {
    final interrogator = controller.interrogatorPlayer!;
    final target = controller.lastInterrogationTargetName;
    return Column(
      children: [
        Text(
          interrogator.interrogationUsed
              ? 'بازجو خبرنگار قابلیتِ یک‌بارمصرفِ بازجویی رو مصرف کرده.'
              : 'بازجو خبرنگار می‌تونه (فقط یک‌بار در کل بازی) یه نفر رو بازجویی کنه:',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (target != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'بازجوییِ انجام‌شده: «$target»'
              '${controller.lastInterrogationQuestion != null ? ' — سوال: ${controller.lastInterrogationQuestion}' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight),
            ),
          ),
        if (!interrogator.interrogationUsed)
          OutlinedButton.icon(
            icon: const Icon(Icons.record_voice_over),
            label: const Text('بازجوییِ یه بازیکن'),
            onPressed: controller.canInterrogateTonight ? _showInterrogationDialog : null,
          ),
      ],
    );
  }

  void _showInterrogationDialog() {
    final targets = controller.alivePlayers;
    SessionPlayer? selectedTarget;
    final questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('بازجویی', style: TextStyle(color: AppColors.goldLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<SessionPlayer>(
                isExpanded: true,
                hint: const Text('انتخابِ هدف', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppColors.surfaceDark,
                value: selectedTarget,
                items: targets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTarget = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'سوال (اختیاری، فقط یادآوریِ خودت)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selectedTarget != null
                  ? () {
                      controller.interrogate(selectedTarget!.id, question: questionController.text);
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: const Text('ثبت'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebelSection() {
    final rebel = controller.rebelPlayer!;
    final armed = controller.armedPlayers;
    return Column(
      children: [
        Text(
          'شورشی می‌تونه امشب به هر تعداد بازیکن اسلحه بده. اسلحه‌ی جنگیِ '
          'باقیمانده: ${rebel.warGunsRemaining ?? 0} (مشقی نامحدوده).',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        if (armed.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: armed
                .map(
                  (p) => Chip(
                    label: Text(
                      '${p.name} (${p.heldGunType == GunType.war ? 'جنگی' : 'مشقی'})',
                    ),
                    backgroundColor: AppColors.surfaceCard,
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.takeBackGun(p.id),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.front_hand),
          label: const Text('دادنِ اسلحه به یه بازیکن'),
          onPressed: () => _showGiveGunDialog(rebel),
        ),
      ],
    );
  }

  void _showGiveGunDialog(SessionPlayer rebel) {
    final targets = controller.alivePlayers;
    SessionPlayer? selectedTarget;
    GunType selectedType = GunType.blank;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('دادنِ اسلحه', style: TextStyle(color: AppColors.goldLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<SessionPlayer>(
                isExpanded: true,
                hint: const Text('انتخابِ بازیکن', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppColors.surfaceDark,
                value: selectedTarget,
                items: targets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTarget = v),
              ),
              const SizedBox(height: 8),
              RadioListTile<GunType>(
                value: GunType.blank,
                groupValue: selectedType,
                activeColor: AppColors.gold,
                onChanged: (v) => setDialogState(() => selectedType = v!),
                title: const Text('مشقی', style: TextStyle(color: Colors.white)),
              ),
              RadioListTile<GunType>(
                value: GunType.war,
                groupValue: selectedType,
                activeColor: AppColors.bloodRedLight,
                onChanged: (rebel.warGunsRemaining ?? 0) > 0
                    ? (v) => setDialogState(() => selectedType = v!)
                    : null,
                title: Text(
                  'جنگی (${rebel.warGunsRemaining ?? 0} باقیمانده)',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selectedTarget != null
                  ? () {
                      controller.giveGun(selectedTarget!.id, selectedType);
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSection() {
    final doc = controller.doctorPlayer!;
    final saved = controller.savedPlayersTonight;
    return Column(
      children: [
        Text(
          'دکتر امشب می‌تونه ${controller.doctorNightlyCapacity} نفر رو در برابر '
          'شاتِ شبِ سرکوب نجات بده (${saved.length} از ${controller.doctorNightlyCapacity} استفاده شده).',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          'نجاتِ خودش: ${doc.selfSavesUsed} از ${widget.settings.doctorMaxSelfSaves} بار در کلِ بازی',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (saved.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: saved
                .map(
                  (p) => Chip(
                    label: Text(p.name),
                    backgroundColor: AppColors.surfaceCard,
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.undoDoctorSave(p.id),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.healing),
          label: const Text('نجاتِ یه بازیکنِ دیگه'),
          onPressed: controller.canDoctorSaveTonight ? () => _showDoctorSavePicker(doc) : null,
        ),
      ],
    );
  }

  void _showDoctorSavePicker(SessionPlayer doc) {
    final targets =
        controller.alivePlayers.where((p) => controller.canDoctorSaveTarget(p.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('امشب کی رو نجات بده؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            if (targets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('کسی برای نجات باقی نمونده.', style: TextStyle(color: Colors.white38)),
              ),
            ...targets.map(
              (p) => ListTile(
                title: Text(
                  p.id == doc.id ? '${p.name} (خودش)' : p.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  controller.doctorSave(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHackerSection() {
    final result = controller.lastInvestigationResult;
    final targetName = controller.lastInvestigationTargetName;
    return Column(
      children: [
        const Text(
          'هکر می‌تونه امشب یکی از بازیکن‌ها رو استعلام بگیره:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (result != null && targetName != null) ...[
          Text(
            result == InvestigationResult.like
                ? '🔍 نتیجه‌ی «$targetName»: 👍 لایک'
                : '🔍 نتیجه‌ی «$targetName»: 👎 دیس‌لایک',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'این نتیجه رو فقط خصوصی و درِگوشی به خودِ هکر بگو.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('استعلامِ یه بازیکن'),
          onPressed: controller.canHackerInvestigateTonight ? _showHackerInvestigatePicker : null,
        ),
      ],
    );
  }

  void _showHackerInvestigatePicker() {
    final hacker = controller.hackerPlayer!;
    final targets = controller.alivePlayers.where((p) => p.id != hacker.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('استعلام روی کی؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.hackerInvestigate(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevolutionarySection() {
    final fighter = controller.revolutionaryFighterPlayer!;
    final charges = fighter.revolutionaryChargesRemaining ?? 0;
    return Column(
      children: [
        Text(
          'مبارز انقلابی: $charges استفاده‌ی باقیمانده از اعدامِ انقلابی/سلاخی'
          '${fighter.canStillSlaughter ? '' : ' (سلاخی دیگه در دسترسش نیست)'}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.gavel),
              label: const Text('اعدامِ انقلابی'),
              onPressed: (controller.canRevolutionaryActTonight && charges > 0)
                  ? () => _showRevolutionaryExecutePicker(fighter)
                  : null,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.content_cut),
              label: const Text('سلاخی'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.bloodRedLight),
              onPressed: (controller.canRevolutionaryActTonight &&
                      charges > 0 &&
                      fighter.canStillSlaughter)
                  ? () => _showRevolutionarySlaughterPicker(fighter)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showRevolutionaryExecutePicker(SessionPlayer fighter) {
    final targets = controller.alivePlayers.where((p) => p.id != fighter.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('اعدامِ انقلابی روی کی؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.revolutionaryExecute(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevolutionarySlaughterPicker(SessionPlayer fighter) {
    final targets = controller.alivePlayers.where((p) => p.id != fighter.id).toList();
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
                              controller.revolutionarySlaughter(selectedTarget!.id, selectedRoleId!);
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

  Widget _buildLawyerSection() {
    final lawyer = controller.lawyerPlayer!;
    final halfAlive = controller.halfAlivePlayers;
    return Column(
      children: [
        Text(
          lawyer.isAlive
              ? 'وکیل هنوز قابلیتِ یک‌بارمصرفِ جان‌بخشیش رو مصرف نکرده.'
              : 'وکیل («${lawyer.name}») خودش الان نیمه‌جانه یا حذف شده و نمی‌تونه فعلاً از این قابلیت استفاده کنه.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (halfAlive.isEmpty)
          const Text(
            'فعلاً هیچ بازیکنِ نیمه‌جانی برای برگردوندن نیست.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.favorite),
            label: const Text('برگردوندنِ یه بازیکنِ نیمه‌جان'),
            onPressed: controller.canLawyerReviveTonight ? _showLawyerRevivePicker : null,
          ),
      ],
    );
  }

  void _showLawyerRevivePicker() {
    final targets = controller.halfAlivePlayers;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('کی به بازی برگرده؟', style: TextStyle(color: AppColors.goldLight)),
            ),
            ...targets.map(
              (p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.lawyerRevive(p.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
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
    final targets =
        controller.alivePlayers.where((p) => minister == null || p.id != minister.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('با کی می‌خوان مذاکره کنن؟', style: TextStyle(color: AppColors.goldLight)),
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
