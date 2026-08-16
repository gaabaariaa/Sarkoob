import 'package:flutter/foundation.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';

/// نتیجه‌ی نهاییِ حل‌وفصلِ رأی‌گیریِ یه روز.
class VoteResolution {
  final String message;
  const VoteResolution(this.message);
}

/// یه رکوردِ چالش: کی (giver) به کی (receiver) چالش داده، برای نمایش و ثبت.
class ChallengeRecord {
  final int giverId;
  final int receiverId;
  const ChallengeRecord(this.giverId, this.receiverId);
}

/// عکسِ لحظه‌ایِ فاز/روزِ فعلی، قبل از هر انتقالِ فاز — فقط برای دکمه‌ی
/// «برگشت یه مرحله». اقدام‌های ثبت‌شده (رأی، تصمیمِ شب، حذف) رو برنمی‌گردونه؛
/// فقط نشانگرِ فاز/روز رو، برای وقتی گرداننده اشتباهی «ادامه» رو زده.
class _PhaseSnapshot {
  final GamePhaseType phase;
  final int roundNumber;
  const _PhaseSnapshot(this.phase, this.roundNumber);
}

/// ترتیبِ «بیدارشدنِ» شب: اول تیمِ سرکوب باهم، بعد هر نقشِ خاصِ شهروندی
/// جداگونه و به‌ترتیب، و در آخر جمع‌بندیِ شب.
enum NightStepKind {
  sorkoobTeam,
  mafiaTeam,
  mossadLeader,
  rapper,
  hacker,
  politicalAnalyst,
  doctor,
  rebel,
  nationalHero,
  revolutionary,
  civicActivist,
  lawyer,
  done,
}

/// موتور اصلی «گردانندگی» یه جلسه‌ی بازی: ترتیب صحبت، چالش، رأی‌گیری،
/// دفاعیه، حذف، و شب (تصمیمِ رهبر سرکوب، مذاکره، حکم اعدام).
class GameFlowController extends ChangeNotifier {
  final List<SessionPlayer> players;
  GameSettings settings;

  GamePhaseType phase = GamePhaseType.introDay;
  int roundNumber = 0;

  GameFlowController({required this.players, required this.settings}) {
    _rebuildSpeakingOrder();
    final suppressionCount =
        players.where((p) => p.teamId == SarkoobTeams.suppression.id).length;
    statusInquiryChargesRemaining = suppressionCount > 0 ? suppressionCount - 1 : 0;
  }

  List<SessionPlayer> get alivePlayers => players.where((p) => p.isAlive).toList();

  SessionPlayer playerById(int id) => players.firstWhere((p) => p.id == id);

  int get aliveCount => alivePlayers.length;
  int get majorityThreshold => (aliveCount / 2).ceil();

  /// شمارشِ بازیکنانِ زنده به‌تفکیکِ تیم — فقط تیم‌هایی که واقعاً تو این
  /// جلسه بازیکن دارن (سرکوب و شهروند همیشه، مستقل فقط اگه فعال باشه).
  /// ترتیب: سرکوب، شهروند، بعد بقیه. اگه همه‌ی یه تیم حذف شده باشن، بازم
  /// با شمارشِ ۰ نشون داده می‌شه (خودش یه اطلاعاتِ مهمه، نه چیزی که مخفی بشه).
  List<MapEntry<GameTeam, int>> get aliveCountsByTeam {
    final presentTeamIds = players.map((p) => p.teamId).toSet();
    final orderedIds = [
      SarkoobTeams.suppression.id,
      SarkoobTeams.citizen.id,
      ...presentTeamIds.where(
        (id) => id != SarkoobTeams.suppression.id && id != SarkoobTeams.citizen.id,
      ),
    ];
    return [
      for (final id in orderedIds)
        if (presentTeamIds.contains(id) && SarkoobTeams.byId(id) != null)
          MapEntry(
            SarkoobTeams.byId(id)!,
            players.where((p) => p.teamId == id && p.isAlive).length,
          ),
    ];
  }

  /// نقش‌هایی که واقعاً تو همین جلسه انتخاب شدن (یعنی حداقل یه بازیکن
  /// دارتشون) — نه کلِ کتابخونه‌ی نقش‌ها. برای منوهای «حدسِ نقش» (سلاخی،
  /// ترورِ موساد) استفاده می‌شه تا فقط نقش‌های واقعاً درگیرِ این بازی
  /// نشون داده بشن. ترتیب طبقِ همون ترتیبِ ثابتِ SarkoobRoles.all ـه.
  List<GameRole> get rolesInPlay {
    final idsInPlay = players.map((p) => p.roleId).whereType<String>().toSet();
    return SarkoobRoles.all.where((r) => idsInPlay.contains(r.id)).toList();
  }

  /// مثلِ rolesInPlay، ولی فقط نقش‌های یه تیمِ خاص (مثلاً برای ترورِ
  /// موساد که فقط باید بینِ نقش‌های تیمِ سرکوب حدس بزنه).
  List<GameRole> rolesInPlayForTeam(String teamId) =>
      rolesInPlay.where((r) => r.teamId == teamId).toList();

  // ---------- ابزارِ گرداننده: جابه‌جاییِ ترتیب و اخراجِ انضباطی ----------
  // این دوتا مستقل از فازِ فعلیِ بازی‌ان (هم شب هم روز در دسترسن) و
  // فقط با آی‌دیِ خودِ بازیکن کار می‌کنن، پس جابه‌جاکردنِ ترتیب هیچ
  // نقش/رأی/زنده‌بودنی رو به‌هم نمی‌ریزه.

  /// ترتیبِ فهرستِ بازیکنان رو عوض می‌کنه (مثلاً اگه سرِ میز جابه‌جا شدن).
  /// چون همه‌جای دیگه با id کار می‌شه نه اندیس، این تغییر امن‌ه؛ فقط از
  /// روزِ بعد رو ترتیبِ نوبتِ صحبت اثر می‌ذاره، وسطِ یه روز/شبِ در جریان
  /// چیزی رو خراب نمی‌کنه.
  void reorderPlayers(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final player = players.removeAt(oldIndex);
    players.insert(newIndex, player);
    notifyListeners();
  }

  String? disciplinaryExpelMessage;

  /// اخراجِ انضباطیِ گرداننده (افشای نقش، تقلب، و مواردِ مشابه). برگشت‌ناپذیره
  /// — حتی وکیل نمی‌تونه برش گردونه — و مستقل از فازِ فعلیِ بازیه. هر
  /// اخراج (چه مستقیم چه بعدِ چهارمین تنبیه) نمره‌ی انضباطی رو هم به
  /// حداکثر (۴) می‌رسونه تا تو آمار «بی‌انضباط‌ترین بازیکن» درست حساب بشه.
  void disciplinaryExpel(int targetId, String reason) {
    final target = playerById(targetId);
    if (!target.isAlive) return;
    target.isAlive = false;
    target.isHalfAlive = false;
    if (target.disciplineStage < 4) target.disciplineStage = 4;
    _checkZhinaTrigger(target);
    _skipDeadSpeakers();
    disciplinaryExpelMessage =
        '«${target.name}» به دلیلِ «$reason» توسطِ گرداننده از بازی اخراج شد.';
    notifyListeners();
  }

  // ---------- تنبیهِ انضباطیِ درجه‌بندی‌شده: اخطار → منعِ چالش‌گرفتن → سکوت → اخراج ----------
  // چهار مرحله‌ست و هربار که این ابزار برای یه بازیکن استفاده بشه، یه
  // درجه جلوتر می‌ره (برگشت‌ناپذیر، نمی‌شه درجه رو پایین آورد). نتیجه‌ی
  // هر درجه با disciplineStageLabel (تو game_session.dart) هم‌خونی داره.

  /// آیا این بازیکن الان (طبقِ روز/فازِ فعلی) از هدفِ چالش‌قرارگرفتن
  /// (چالش‌گرفتن) منعه — یعنی کسی نمی‌تونه بهش چالش بده، نه اینکه خودش
  /// نتونه به بقیه چالش بده. چه منعِ همیشگی (مرحله‌ی ۳+) چه منعِ
  /// یک‌روزه‌ی مرحله‌ی ۲، فقط تو همون روزی که برای‌ش ثبت شده.
  bool isChallengeBanned(SessionPlayer p) {
    if (p.challengeBannedForever) return true;
    return p.challengeBanRoundNumber != null &&
        phase == GamePhaseType.day &&
        p.challengeBanRoundNumber == roundNumber;
  }

  /// آیا این بازیکن امروز سکوتِ انضباطی داره (نوبتِ صحبتش باید رد بشه)؟
  bool isSilencedToday(SessionPlayer p) =>
      p.silencedRoundNumber != null &&
      phase == GamePhaseType.day &&
      p.silencedRoundNumber == roundNumber;

  /// درجه‌ی بعدی رو برای این بازیکن اعمال می‌کنه و پیامِ نتیجه رو
  /// برمی‌گردونه (برای نمایش به گرداننده). مرحله‌ی چهارم مستقیم از همون
  /// disciplinaryExpel استفاده می‌کنه تا رفتارش (حذفِ کامل، ژینا، صفِ
  /// نوبت) دقیقاً یکی باشه.
  String applyNextDisciplineStage(int targetId, String reason) {
    final target = playerById(targetId);
    final effectiveReason = reason.trim().isEmpty ? 'نامشخص' : reason.trim();
    final nextStage = target.disciplineStage + 1;

    if (nextStage >= 4) {
      disciplinaryExpel(targetId, 'چهارمین تخلفِ انضباطی — $effectiveReason');
      return '«${target.name}» برای چهارمین‌بار تخلف کرد و از بازی اخراج شد.';
    }

    target.disciplineStage = nextStage;
    final effectiveRound = phase == GamePhaseType.day ? roundNumber : roundNumber + 1;
    String message;
    switch (nextStage) {
      case 1:
        message = '«${target.name}» اخطار گرفت (دلیل: $effectiveReason).';
        break;
      case 2:
        target.challengeBanRoundNumber = effectiveRound;
        message =
            '«${target.name}» امروز نمی‌تونه چالش بگیره؛ یعنی کسی نمی‌تونه بهش چالش بده (دلیل: $effectiveReason).';
        break;
      default: // 3
        target.challengeBannedForever = true;
        target.silencedRoundNumber = effectiveRound;
        _skipDeadSpeakers();
        message = '«${target.name}» برای‌همیشه از چالش‌گرفتن منع شد و تا پایانِ امروز '
            'سکوتِ انضباطی داره (دلیل: $effectiveReason).';
        break;
    }
    notifyListeners();
    return message;
  }

  // ---------- ترتیب صحبت ----------

  List<int> _speakingOrder = [];
  int _speakerPointer = 0;

  void _rebuildSpeakingOrder() {
    _speakingOrder = alivePlayers.map((p) => p.id).toList();
    _speakerPointer = 0;
    _todaysChallenges.clear();
    for (final p in players) {
      p.hasSpokenThisRound = false;
      p.challengeReceivedToday = false;
      p.challengeGivenToday = false;
    }
    // اگه یکی دیشب (یا زودتر امروز) تنبیهِ سکوتِ انضباطی گرفته باشه و
    // قرار باشه امروز سکوتش فعال بشه، نباید اولین نفرِ نوبتِ صحبتِ امروز
    // بشه — وگرنه _skipDeadSpeakers هیچ‌وقت صداش نمی‌زنه که ردش کنه.
    _skipDeadSpeakers();
  }

  SessionPlayer? get currentSpeaker =>
      _speakerPointer < _speakingOrder.length ? playerById(_speakingOrder[_speakerPointer]) : null;

  bool get isSpeakingRoundDone => _speakerPointer >= _speakingOrder.length;

  int? _activeChallengerId;
  int? get activeChallengerId => _activeChallengerId;

  /// کسی که الان باید صحبت کنه: یا چالش‌گیرنده‌ی فعال، یا نفرِ نوبت عادی.
  SessionPlayer? get speakerForDisplay {
    if (_activeChallengerId != null) return playerById(_activeChallengerId!);
    return currentSpeaker;
  }

  /// مدت‌زمان مجاز صحبتِ همین الان، بسته به نوع نوبت.
  int get currentTurnSeconds {
    if (_activeChallengerId != null) return settings.challengeSeconds;
    if (phase == GamePhaseType.introDay) return settings.introSeconds;
    return settings.speakSeconds;
  }

  void advanceSpeaker() {
    final speaker = currentSpeaker;
    if (speaker != null) speaker.hasSpokenThisRound = true;
    _speakerPointer++;
    _skipDeadSpeakers();
    notifyListeners();
  }

  /// وقتی وسطِ روز یکی حذف می‌شه (اخراجِ انضباطی، ترورِ مزدور، اسلحه‌ی
  /// جنگی، کلمه‌ی ممنوع)، باید از صفِ نوبتِ صحبت هم خارج بشه — چه نوبتِ
  /// عادیِ باقی‌مونده چه یه چالشِ درجریان — وگرنه گرداننده نوبتِ یه
  /// بازیکنِ مرده رو می‌بینه. کسی که قبلاً نوبتش تموم شده رو دست‌نخورده
  /// می‌ذاره (چیزی برای ردکردن نیست). بازیکنِ سکوتِ انضباطی‌گرفته هم دقیقاً
  /// همینجا رد می‌شه — نوبتش می‌رسه ولی گرداننده باید ردش کنه، پس برای
  /// حسابِ «باقی‌مونده» انگار صحبتش رو کرده.
  void _skipDeadSpeakers() {
    if (_activeChallengerId != null) {
      final challenger = playerById(_activeChallengerId!);
      if (!challenger.isAlive || isSilencedToday(challenger)) {
        _activeChallengerId = null;
      }
    }
    while (_speakerPointer < _speakingOrder.length) {
      final p = playerById(_speakingOrder[_speakerPointer]);
      if (!p.isAlive) {
        _speakerPointer++;
        continue;
      }
      if (isSilencedToday(p)) {
        p.hasSpokenThisRound = true;
        _speakerPointer++;
        continue;
      }
      break;
    }
  }

  /// بازیکن‌هایی که الان می‌تونن هدفِ چالش باشن (فقط توی روزهای عادی، و
  /// فقط کسایی که امروز قبلاً چالش نگرفتن، سکوتِ انضباطی ندارن، و از
  /// چالش‌گرفتن منع نشدن).
  List<SessionPlayer> get challengeEligiblePlayers {
    if (phase != GamePhaseType.day) return const [];
    return alivePlayers
        .where((p) =>
            !p.challengeReceivedToday &&
            p.id != speakerForDisplay?.id &&
            !isSilencedToday(p) &&
            !isChallengeBanned(p))
        .toList();
  }

  /// آیا کسی که الان نوبتِ عادیِ صحبتشه، می‌تونه (هنوز) به یکی چالش بده؟
  /// هر بازیکن توی هر نوبتِ صحبتش فقط یک‌بار می‌تونه چالش بده. تنبیهِ
  /// انضباطیِ «منعِ چالش‌گرفتن» خودِ چالش‌دهنده رو محدود نمی‌کنه — فقط
  /// باعث می‌شه بازیکنِ منع‌شده جزوِ اهدافِ قابل‌انتخاب نباشه
  /// (challengeEligiblePlayers).
  bool get canCurrentSpeakerGiveChallenge {
    final speaker = currentSpeaker;
    return speaker != null && !speaker.challengeGivenToday;
  }

  final List<ChallengeRecord> _todaysChallenges = [];
  List<ChallengeRecord> get todaysChallenges => List.unmodifiable(_todaysChallenges);

  /// یه بازیکن (نوبتِ عادیِ فعلی) به یه بازیکنِ دیگه چالش می‌ده؛ بعدش
  /// نوبتِ عادی دست‌نخورده می‌مونه. کی‌به‌کی برای نمایش ثبت می‌شه. اگه
  /// گیرنده از چالش‌گرفتن منع شده باشه (تنبیهِ انضباطی)، چالش رد می‌شه —
  /// نه محدودیتی رو خودِ چالش‌دهنده.
  void useChallenge(int receiverId) {
    final giver = currentSpeaker;
    if (giver == null || giver.challengeGivenToday) return;
    final receiver = playerById(receiverId);
    if (receiver.challengeReceivedToday ||
        isSilencedToday(receiver) ||
        isChallengeBanned(receiver)) {
      return;
    }
    giver.challengeGivenToday = true;
    receiver.challengeReceivedToday = true;
    _todaysChallenges.add(ChallengeRecord(giver.id, receiverId));
    _activeChallengerId = receiverId;
    notifyListeners();
  }

  void finishChallenge() {
    _activeChallengerId = null;
    notifyListeners();
  }

  // ---------- انتقال بین فازها ----------

  final List<_PhaseSnapshot> _phaseHistory = [];

  /// آیا الان می‌شه یه مرحله (نه به منو، فقط فاز/روزِ قبلی) برگشت؟
  bool get canStepBackPhase => _phaseHistory.isNotEmpty;

  /// دکمه‌ی بک (چه سیستمی چه AppBar) به‌جای خروج به منو، همینو صدا می‌زنه:
  /// فقط نشانگرِ فاز/روز رو یه قدم برمی‌گردونه، برای وقتی گرداننده اشتباهی
  /// «ادامه» زده. رأی/تصمیمِ ثبت‌شده رو دست‌نمی‌زنه — اونا رو گرداننده باید
  /// خودش با ابزارهای دیگه (مثلاً +/- رأی) دستی اصلاح کنه.
  void stepBackOnePhase() {
    if (_phaseHistory.isEmpty) return;
    final previous = _phaseHistory.removeLast();
    phase = previous.phase;
    roundNumber = previous.roundNumber;
    notifyListeners();
  }

  void moveToIntroNight() {
    _phaseHistory.add(_PhaseSnapshot(phase, roundNumber));
    phase = GamePhaseType.introNight;
    notifyListeners();
  }

  void moveToDay(int dayNumber) {
    _phaseHistory.add(_PhaseSnapshot(phase, roundNumber));
    phase = GamePhaseType.day;
    roundNumber = dayNumber;
    _rebuildSpeakingOrder();
    votingStarted = false;
    _defenseCandidateIds = [];
    _defensePointer = 0;
    _isSecondRound = false;
    for (final p in players) {
      p.votes = 0;
    }
    lastResolution = null;
    gunFireResultMessage = null;
    gunExplosionSummary = null;
    if (pendingExecutionWord != null) {
      activeExecutionWord = pendingExecutionWord;
      pendingExecutionWord = null;
    }
    // اگه دیشب فعالِ مدنی درخواستِ رفراندوم داده بود، امروز — درست قبل از
    // رأی‌گیریِ حذف — رفراندوم برگزار می‌شه.
    referendumScheduledToday = _referendumRequestedThisNight;
    communityLeaderId = null;
    communityLeaderExpulsionMessage = null;
    _referendumVotes.clear();
    _referendumCandidateIds = null;
    notifyListeners();
  }

  // ---------- رأی‌گیری دور اول ----------

  bool votingStarted = false;

  void startVoting() {
    // اول: اسلحه‌ی جنگیِ استفاده‌نشده منفجر می‌شه و صاحبش حذف می‌شه — این
    // هم مثلِ شلیکِ واقعی «استفاده» حساب می‌شه (شورشی دیگه بیدار نمی‌شه)،
    // چون گیرنده فرصتِ کاملِ یه روز رو داشت و به‌کارش نبرد. اسلحه‌ی مشقیِ
    // استفاده‌نشده هم فقط بی‌سروصدا پاک می‌شه.
    final explosions = <String>[];
    for (final p in players) {
      if (!p.isAlive || p.heldGunType == null) continue;
      if (p.heldGunType == GunType.war) {
        explosions.add(
          '«${p.name}» تا شروعِ رأی‌گیری شلیک نکرد؛ اسلحه‌ی جنگی دستِ خودش منفجر شد و از بازی خارج شد.',
        );
        _eliminatePlayer(p);
        rebelWarGunUsed = true;
      }
      p.heldGunType = null;
    }
    gunExplosionSummary = explosions.isEmpty ? null : explosions.join('\n');

    votingStarted = true;
    activeExecutionWord = null; // پنجره‌ی «کلمه‌ی ممنوع» با شروعِ رأی‌گیری بسته می‌شه
    for (final p in alivePlayers) {
      p.votes = 0;
    }
    notifyListeners();
  }

  void addVote(int playerId) {
    playerById(playerId).votes += 1;
    notifyListeners();
  }

  void removeVote(int playerId) {
    final p = playerById(playerId);
    if (p.votes > 0) p.votes -= 1;
    notifyListeners();
  }

  List<int> _defenseCandidateIds = [];
  int _defensePointer = 0;
  bool _isSecondRound = false;
  VoteResolution? lastResolution;

  List<SessionPlayer> get defenseCandidates => _defenseCandidateIds.map(playerById).toList();

  /// آیا الان توی بازه‌ی دفاعیه‌ایم؟
  bool get inDefense =>
      _defenseCandidateIds.isNotEmpty && !_isSecondRound && lastResolution == null;

  bool get isSecondVoteRound => _isSecondRound;

  /// بعد از رأی‌گیریِ اول: چه کسانی وارد دفاعیه می‌شن؟
  void resolveFirstVoteRound() {
    _defenseCandidateIds = alivePlayers
        .where((p) => p.votes >= majorityThreshold && p.id != guaranteedPlayerId)
        .map((p) => p.id)
        .toList();
    _defensePointer = 0;
    if (_defenseCandidateIds.isEmpty) {
      lastResolution = const VoteResolution('هیچ‌کس رأی کافی نیاورد؛ امروز کسی وارد دفاعیه نشد.');
    }
    notifyListeners();
  }

  // ---------- دفاعیه ----------

  SessionPlayer? get currentDefenseSpeaker {
    if (_defensePointer >= _defenseCandidateIds.length) return null;
    return playerById(_defenseCandidateIds[_defensePointer]);
  }

  bool get isDefenseRoundDone => _defensePointer >= _defenseCandidateIds.length;

  void advanceDefenseSpeaker() {
    _defensePointer++;
    notifyListeners();
  }

  void startSecondVoteRound() {
    _isSecondRound = true;
    for (final id in _defenseCandidateIds) {
      playerById(id).votes = 0;
    }
    notifyListeners();
  }

  void resolveSecondVoteRound() {
    if (_defenseCandidateIds.length == 1) {
      final only = playerById(_defenseCandidateIds.first);
      if (only.votes >= majorityThreshold) {
        _eliminatePlayer(only);
        lastResolution = VoteResolution('«${only.name}» با رأی کافی حذف شد.');
      } else {
        only.recordCount++;
        lastResolution = VoteResolution('«${only.name}» رأی کافی نیاورد و سابقه‌دار شد.');
      }
    } else if (_defenseCandidateIds.isNotEmpty) {
      final candidates = _defenseCandidateIds.map(playerById).toList();
      final maxVotes = candidates.map((p) => p.votes).reduce((a, b) => a > b ? a : b);
      final topByVotes = candidates.where((p) => p.votes == maxVotes).toList();

      SessionPlayer? eliminated;
      if (topByVotes.length == 1) {
        eliminated = topByVotes.first;
      } else {
        final maxRecord = topByVotes.map((p) => p.recordCount).reduce((a, b) => a > b ? a : b);
        final topByRecord = topByVotes.where((p) => p.recordCount == maxRecord).toList();
        if (topByRecord.length == 1) {
          eliminated = topByRecord.first;
        }
      }

      if (eliminated != null) {
        final eliminatedId = eliminated.id;
        _eliminatePlayer(eliminated);
        for (final p in candidates) {
          if (p.id != eliminatedId) p.recordCount++;
        }
        lastResolution = VoteResolution('«${eliminated.name}» حذف شد.');
      } else {
        for (final p in candidates) {
          p.recordCount++;
        }
        lastResolution = const VoteResolution('رأی و سابقه‌ی نفرات دفاعیه برابر بود؛ امروز کسی حذف نشد.');
      }
    }

    _isSecondRound = false;
    notifyListeners();
  }

  // ---------- شب: تصمیمِ رهبر تیم سرکوب (شات / سلاخی / مذاکره) ----------

  final Map<int, int> _pendingHits = {}; // targetId -> تعداد ضربه‌ی وارده
  final Set<int> _savedPlayerIds = {}; // بازیکنانی که دکتر امشب نجات‌شون داده
  int _doctorSavesUsedTonight = 0;
  bool _nightActionTaken = false;
  String? slaughterResultMessage;
  String? negotiateResultMessage;

  /// این سه‌تا مخصوصِ خلاصه‌ی دسته‌بندی‌شده‌ی صبحه: طبقِ قانون، اولِ روز
  /// باید صریحاً اعلام بشه کی با سلاخی حذف شد، کی به‌شکلِ عادی حذف شد، و
  /// کی رو وکیل برگردوند. با id کار می‌کنن (نه اسم، چون اسم‌ها ممکنه
  /// تکراری باشن). هر شبِ جدید (تو moveToNight) خالی می‌شن.
  final List<int> _tonightSlaughteredIds = [];
  final List<int> _tonightEliminatedIds = [];
  int? _tonightRevivedId;

  /// آیا این بازیکن هنوز می‌تونه امشب از قابلیتِ نقشِ خودش استفاده کنه؟
  /// «زنده»ی معمولی، یا اگه همین امشب سلاخی/ترور شده (حذفش هنوز نهایی
  /// نشده، فقط تهِ شب با finishNight قطعی می‌شه). این فقط برای خودِ
  /// صاحبِ نقش (actor) استفاده می‌شه، نه برای لیستِ هدف‌های قابل‌انتخاب —
  /// یکی که امشب سلاخی شده دیگه هدفِ نجات/بازداشت و... نمی‌تونه باشه،
  /// ولی خودش هنوز نوبتِ خودش رو داره چون شب هنوز تموم نشده.
  bool _stillActiveTonight(SessionPlayer p) =>
      p.isAlive || (phase == GamePhaseType.night && _tonightSlaughteredIds.contains(p.id));

  /// ژینا: اگه دیشب حذف شده باشه، این true می‌شه و امشب مصرفش می‌کنیم.
  bool sorkoobDisabledNextNight = false;

  /// همینِ امشب، تیمِ سرکوب هیچ قابلیتی نداره (چون ژینا دیشب حذف شد).
  bool sorkoobDisabledTonight = false;

  bool get nightActionTaken => _nightActionTaken;

  SessionPlayer? get valiFaghihPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.valiFaghih.id) return p;
    }
    return null;
  }

  SessionPlayer? get foreignMinisterPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.foreignMinister.id) return p;
    }
    return null;
  }

  /// آیا حداقل یه عضوِ تیم سرکوب تا الان از بازی خارج شده؟
  bool get sorkoobHasLostMember =>
      players.any((p) => p.teamId == SarkoobTeams.suppression.id && !p.isAlive);

  /// آیا این بازیکن یه شهروندِ «خاکستری»ه؟ (بدونِ نقشِ خاص). چون بازیکنانِ
  /// بدونِ نقشِ خاص از این به بعد صراحتاً roleId=grayCitizen می‌گیرن، هم
  /// اون حالت هم حالتِ قدیمیِ null رو پوشش می‌دیم.
  bool _isGrayCitizen(SessionPlayer p) =>
      p.teamId == SarkoobTeams.citizen.id &&
      (p.roleId == null || p.roleId == SarkoobRoles.grayCitizen.id);

  /// شهروندهای «خاکستری»: زنده، عضو تیم شهروند، و بدون نقشِ خاص.
  List<SessionPlayer> get grayCitizens =>
      players.where((p) => p.isAlive && _isGrayCitizen(p)).toList();

  bool get canUseNegotiate {
    if (sorkoobDisabledTonight) return false;
    final minister = foreignMinisterPlayer;
    if (minister == null || !minister.isAlive) return false;
    if (isPlayerDetained(minister.id)) return false;
    if (!sorkoobHasLostMember) return false;
    if (grayCitizens.isEmpty) return false;
    return true;
  }

  void leaderNegotiate(int targetId) {
    if (sorkoobDisabledTonight) return;
    final minister = foreignMinisterPlayer;
    if (minister == null || isPlayerDetained(minister.id)) return;
    final target = playerById(targetId);
    final isGrayCitizen = _isGrayCitizen(target);
    if (isGrayCitizen) {
      target.teamId = SarkoobTeams.suppression.id;
      target.roleId = SarkoobRoles.suppressor.id;
      negotiateResultMessage = 'مذاکره با موفقیت صورت گرفت.';
    } else {
      negotiateResultMessage = 'مذاکره با شکست مواجه شد.';
    }
    _nightActionTaken = true;
    notifyListeners();
  }

  void leaderShoot(int targetId) {
    if (sorkoobDisabledTonight) return;
    final leader = valiFaghihPlayer;
    if (leader == null || isPlayerDetained(leader.id)) return;
    _pendingHits[targetId] = (_pendingHits[targetId] ?? 0) + 1;
    _nightActionTaken = true;
    notifyListeners();
  }

  void leaderSlaughter(int targetId, String guessedRoleId) {
    if (sorkoobDisabledTonight) return;
    final leader = valiFaghihPlayer;
    if (leader == null || isPlayerDetained(leader.id)) return;
    final target = playerById(targetId);
    final correct = target.roleId == guessedRoleId;
    if (correct) {
      target.isAlive = false;
      target.eliminatedBySlaughter = true;
      _checkZhinaTrigger(target);
      _tonightSlaughteredIds.add(target.id);
      slaughterResultMessage = '«${target.name}» با سلاخی از بازی خارج شد.';
    } else {
      if ((leader.slaughterChargesRemaining ?? 0) > 0) {
        leader.slaughterChargesRemaining = leader.slaughterChargesRemaining! - 1;
      }
      slaughterResultMessage = 'حدس درست نبود؛ یک ظرفیتِ سلاخی مصرف شد.';
    }
    _nightActionTaken = true;
    notifyListeners();
  }

  // ---------- شب: تصمیمِ تیمِ مافیا (سناریوی مافیا) ----------

  /// اعضای زنده‌ی مافیا — برای نمایشِ لیستِ کامل، مثلِ نمایشِ تیمِ سرکوب.
  List<SessionPlayer> get aliveMafiaTeamPlayers =>
      alivePlayers.where((p) => p.teamId == SarkoobTeams.mafiaGang.id).toList();

  /// آیا امشب حداقل یه عضوِ زنده‌ی مافیا برای تصمیم‌گیری هست؟
  bool get canMafiaTeamAct => aliveMafiaTeamPlayers.isNotEmpty;

  /// آیا می‌شه از مرحله‌ی تیمِ مافیا جلوتر رفت؟ اگه اصلاً عضوِ زنده‌ای
  /// نمونده، بدونِ تصمیم هم می‌شه رد شد؛ وگرنه باید امشب یه هدف انتخاب
  /// شده باشه.
  bool get canAdvancePastMafiaTeamStep => !canMafiaTeamAct || _nightActionTaken;

  /// تیمِ مافیا (با هم) روی یه هدف توافق می‌کنن. مثلِ leaderShoot، فقط
  /// صف‌بندی می‌شه تو همون _pendingHits ی مشترک — یعنی نجاتِ دکتر (اگه
  /// بعداً برای این سناریو اضافه شد) خودکار روش اثر می‌ذاره.
  void mafiaTeamShoot(int targetId) {
    if (!canMafiaTeamAct) return;
    _pendingHits[targetId] = (_pendingHits[targetId] ?? 0) + 1;
    _nightActionTaken = true;
    notifyListeners();
  }

  // ---------- استعلامِ وضعیت (زیرِ گزارشِ پایانِ شب) ----------

  /// چندبار «استعلامِ وضعیت» هنوز مونده. یه‌بار موقعِ ساختنِ کنترلر
  /// محاسبه می‌شه: اندازه‌ی تیمِ سرکوب در شروعِ بازی منهای ۱ (بخشِ
  /// سازنده رو ببین). فقط تو سناریوی سرکوب معنی داره — تو سناریوی مافیا
  /// این تیم اصلاً وجود نداره، پس همیشه ۰ می‌مونه و UI خودش بر همین اساس
  /// پنهانش می‌کنه (نیازی به چکِ جداگونه‌ی سناریو نیست).
  late int statusInquiryChargesRemaining;

  /// آیا الان (زیرِ گزارشِ پایانِ شب) رأی‌گیریِ استعلامِ وضعیت بازه؟
  bool statusInquiryVoteOpen = false;

  /// تعدادِ رأیِ موافقی که گرداننده تا الان تو همین رأی‌گیریِ باز ثبت کرده.
  int statusInquiryYesVotes = 0;

  /// نتیجه‌ی آخرین رأی‌گیریِ امشب: true=اکثریت آورد، false=نیاورد،
  /// null=امشب هنوز امتحان نشده.
  bool? statusInquiryLastVotePassed;

  /// متنِ نتیجه — یا آمارِ عمومیِ قابل‌اعلام (اگه رأی آورد)، یا یه یادداشتِ
  /// کوتاه که رأی نیاورد. `null` یعنی امشب هنوز امتحان نشده.
  String? statusInquiryResultMessage;

  /// شمارشِ بازیکنانِ خارج‌شده از بازی (هرجور خارج‌شدنی — رأی، شات،
  /// سلاخی، اخراجِ انضباطی، ترور، ...) به‌تفکیکِ تیم. برخلافِ
  /// aliveCountsByTeam، تیمی که هیچ حذفی نداشته اصلاً تو لیست نمیاد،
  /// چون استعلامِ وضعیت فقط قراره از خارج‌شده‌ها بگه.
  List<MapEntry<GameTeam, int>> get eliminatedCountsByTeam {
    final counts = <String, int>{};
    for (final p in players.where((p) => !p.isAlive)) {
      counts[p.teamId] = (counts[p.teamId] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        if (SarkoobTeams.byId(entry.key) != null)
          MapEntry(SarkoobTeams.byId(entry.key)!, entry.value),
    ];
  }

  /// رأی‌گیری رو باز می‌کنه (شمارشگرِ موافق‌ها صفر می‌شه). اگه شارژی
  /// نمونده باشه کاری نمی‌کنه.
  void openStatusInquiryVote() {
    if (statusInquiryChargesRemaining <= 0) return;
    statusInquiryVoteOpen = true;
    statusInquiryYesVotes = 0;
    notifyListeners();
  }

  void setStatusInquiryYesVotes(int count) {
    statusInquiryYesVotes = count.clamp(0, aliveCount);
    notifyListeners();
  }

  /// نتیجه‌ی رأی‌گیری رو قطعی می‌کنه. اکثریت یعنی بیشتر از نصفِ زنده‌ها.
  /// فقط وقتی واقعاً رأی بیاره یه شارژ مصرف می‌شه؛ رأی‌نیاوردن رایگانه
  /// (می‌شه شبِ دیگه دوباره امتحان کرد).
  void resolveStatusInquiryVote() {
    statusInquiryVoteOpen = false;
    final passed = statusInquiryYesVotes > aliveCount / 2;
    statusInquiryLastVotePassed = passed;
    if (passed) {
      statusInquiryChargesRemaining--;
      final counts = eliminatedCountsByTeam;
      statusInquiryResultMessage = counts.isEmpty
          ? 'نفراتِ خارج‌شده از بازی: تا الان کسی خارج نشده.'
          : 'نفراتِ خارج‌شده از بازی:\n'
              '${counts.map((e) => '${e.value} نفر ${e.key.name}').join('\n')}';
    } else {
      statusInquiryResultMessage = 'رأی‌گیریِ استعلامِ وضعیت اکثریت نیاورد؛ شارژی مصرف نشد.';
    }
    notifyListeners();
  }

  // ---------- رئیس قوه قضاییه: حکم اعدام (مستقل از تصمیمِ بالا) ----------

  String? pendingExecutionWord; // کلمه‌ای که شب گفته شده، هنوز اعلام نشده
  String? activeExecutionWord; // کلمه‌ای که امروز فعاله و گرداننده اعلامش کرده

  SessionPlayer? get judiciaryChiefPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.judiciaryChief.id) return p;
    }
    return null;
  }

  bool get canIssueExecutionOrder {
    if (sorkoobDisabledTonight) return false;
    final chief = judiciaryChiefPlayer;
    if (chief == null || !chief.isAlive || chief.executionOrderUsed) return false;
    return !isPlayerDetained(chief.id);
  }

  void issueExecutionOrder(String word) {
    if (!canIssueExecutionOrder) return;
    final chief = judiciaryChiefPlayer;
    if (chief == null) return;
    chief.executionOrderUsed = true;
    pendingExecutionWord = word.trim();
    notifyListeners();
  }

  // ---------- بازجو خبرنگار: بازجوییِ یک‌بارمصرف (بخشی از بیداریِ تیمِ سرکوب) ----------

  SessionPlayer? get interrogatorPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.interrogator.id) return p;
    }
    return null;
  }

  bool get canInterrogateTonight {
    if (sorkoobDisabledTonight) return false;
    final interrogator = interrogatorPlayer;
    if (interrogator == null || !interrogator.isAlive || interrogator.interrogationUsed) {
      return false;
    }
    return !isPlayerDetained(interrogator.id);
  }

  String? lastInterrogationTargetName;
  String? lastInterrogationQuestion; // اختیاری، فقط یادآوری برای گرداننده

  /// question اختیاریه، فقط برای این‌که گرداننده یادش بمونه چی پرسیده؛
  /// خودِ جواب (لایک/دیس‌لایک) با اشاره‌ی دستِ واقعیِ بازیکن مشخص می‌شه،
  /// نه چیزی که اپ محاسبه کنه.
  void interrogate(int targetId, {String? question}) {
    if (!canInterrogateTonight) return;
    final interrogator = interrogatorPlayer;
    if (interrogator == null) return;
    interrogator.interrogationUsed = true;
    lastInterrogationTargetName = playerById(targetId).name;
    lastInterrogationQuestion = (question != null && question.trim().isNotEmpty)
        ? question.trim()
        : null;
    notifyListeners();
  }

  // ---------- وزیر اطلاعات: سؤالِ اطلاعاتی (بخشی از بیداریِ تیمِ سرکوب) ----------

  SessionPlayer? get intelligenceMinisterPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.intelligenceMinister.id) return p;
    }
    return null;
  }

  bool _intelQuestionUsedTonight = false;

  bool get canAskIntelQuestionTonight {
    if (sorkoobDisabledTonight) return false;
    final minister = intelligenceMinisterPlayer;
    if (minister == null || !minister.isAlive) return false;
    if (isPlayerDetained(minister.id)) return false;
    if (_intelQuestionUsedTonight) return false;
    return (minister.intelQuestionsRemaining ?? 0) > 0;
  }

  InvestigationResult? lastIntelQuestionResult;
  List<String>? lastIntelQuestionTargetNames;

  /// لایک یعنی همه‌ی هدف‌ها نقشِ خاص دارن؛ دیس‌لایک یعنی حداقل یکی‌شون
  /// نقشِ خاصی نداره (سرکوبگرِ ساده و شهروندِ خاکستری «نقش‌دار» حساب
  /// نمی‌شن، چون نقشِ متمایزکننده‌ای نیستن). به تیم یا استثناهای
  /// استعلامِ هکر کاری نداره — فقط واقعیتِ خامِ «نقشِ خاص داشتن» رو می‌گه.
  void askIntelQuestion(List<int> targetIds) {
    if (!canAskIntelQuestionTonight || targetIds.isEmpty) return;
    final minister = intelligenceMinisterPlayer!;
    minister.intelQuestionsRemaining = (minister.intelQuestionsRemaining ?? 0) - 1;
    _intelQuestionUsedTonight = true;
    final allHaveRoles = targetIds.every((id) {
      final roleId = playerById(id).roleId;
      return roleId != null &&
          roleId != SarkoobRoles.suppressor.id &&
          roleId != SarkoobRoles.grayCitizen.id;
    });
    lastIntelQuestionResult = allHaveRoles ? InvestigationResult.like : InvestigationResult.dislike;
    lastIntelQuestionTargetNames = targetIds.map((id) => playerById(id).name).toList();
    notifyListeners();
  }

  // ---------- فرمانده نیروی انتظامی: بازداشتِ شبانه (بخشی از بیداریِ سرکوب) ----------

  SessionPlayer? get policeCommanderPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.policeCommander.id) return p;
    }
    return null;
  }

  int? detainedPlayerId; // بازداشتیِ همین امشب
  int? _detainedLastNight; // برای جلوگیری از بازداشتِ دو شبِ پیاپیِ یه نفر

  bool isPlayerDetained(int playerId) => detainedPlayerId == playerId;

  bool get canDetainTonight {
    if (sorkoobDisabledTonight) return false;
    final commander = policeCommanderPlayer;
    return commander != null && _stillActiveTonight(commander) && detainedPlayerId == null;
  }

  List<SessionPlayer> get detainEligibleTargets =>
      alivePlayers.where((p) => p.id != _detainedLastNight).toList();

  void detainPlayer(int targetId) {
    if (!canDetainTonight) return;
    if (targetId == _detainedLastNight) return;
    detainedPlayerId = targetId;
    notifyListeners();
  }

  // ---------- مزدور لباس شخصی: ترور (شب یا هر لحظه‌ی روز، جز رأی‌گیری) ----------

  SessionPlayer? get mercenaryPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.mercenary.id) return p;
    }
    return null;
  }

  bool get canAssassinateTonight {
    if (sorkoobDisabledTonight) return false;
    final merc = mercenaryPlayer;
    if (merc == null || !_stillActiveTonight(merc)) return false;
    return !isPlayerDetained(merc.id);
  }

  bool get canAssassinateNow {
    final merc = mercenaryPlayer;
    if (merc == null || !_stillActiveTonight(merc)) return false;
    if (phase == GamePhaseType.day && votingStarted) return false;
    return true;
  }

  String? assassinationResultMessage;

  /// چه شب چه روز صدا زده بشه، خودِ متد شرایطِ لازم رو دوباره چک می‌کنه.
  /// هدف طبقِ قانونِ عادی حذف می‌شه (وکیل می‌تونه نجاتش بده)، ولی خودِ
  /// مزدور همیشه علنی و بلافاصله لو می‌ره و حذف می‌شه (این بخشِ خودِ قانونشه).
  void assassinate(int targetId) {
    final merc = mercenaryPlayer;
    if (merc == null || !_stillActiveTonight(merc)) return;
    if (phase == GamePhaseType.night && isPlayerDetained(merc.id)) return;
    if (phase == GamePhaseType.day && votingStarted) return;
    final target = playerById(targetId);
    // طبقِ اصلاحِ قانون: هدفِ ترورشده هم مثلِ خودِ مزدور کاملاً و
    // برای‌همیشه حذف می‌شه — نه یه حذفِ معمولی که وکیل بتونه خنثاش کنه.
    target.isAlive = false;
    target.isHalfAlive = false;
    _checkZhinaTrigger(target);
    // خودِ مزدور هم برگشت‌ناپذیره: «لو رفتن» یه اتفاقِ قطعیه، نه یه حذفِ
    // معمولی که وکیل بتونه خنثاش کنه.
    merc.isAlive = false;
    merc.isHalfAlive = false;
    _checkZhinaTrigger(merc);
    _skipDeadSpeakers();
    assassinationResultMessage =
        '«${merc.name}» (مزدورِ لباس‌شخصی) «${target.name}» رو ترور کرد و خودش هم لو رفت و همون‌لحظه حذف شد.';
    notifyListeners();
  }

  // ---------- وکیل: جان‌بخشیِ یک‌بارمصرف (مستقل از بقیه) ----------

  SessionPlayer? get lawyerPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.lawyer.id) return p;
    }
    return null;
  }

  /// آیا الان یه «وکیل»ِ استفاده‌نشده تو بازیه؟ (چه خودش الان زنده باشه چه
  /// نباشه — نکته‌ی مهم: اگه خودِ وکیل قبل از استفاده از قابلیتش حذف بشه،
  /// دیگه هیچ‌وقت کسی نمی‌تونه از این قابلیت استفاده کنه، پس نیمه‌جان‌ها
  /// برای همیشه در همون حالت می‌مونن.) تا وقتی جوابش مثبته، بازیکنانِ
  /// حذف‌شده (به‌جز سلاخی‌شده‌ها که مستقیم و برای‌همیشه حذف می‌شن) به‌جای
  /// حذفِ کامل، نیمه‌جان می‌مونن.
  bool get hasUnusedPublicDefender {
    final lawyer = lawyerPlayer;
    return lawyer != null && !lawyer.revivalUsed;
  }

  bool get canLawyerReviveTonight {
    final lawyer = lawyerPlayer;
    if (lawyer == null || !_stillActiveTonight(lawyer) || lawyer.revivalUsed) return false;
    return !isPlayerDetained(lawyer.id);
  }

  List<SessionPlayer> get halfAlivePlayers =>
      players.where((p) => !p.isAlive && p.isHalfAlive).toList();

  /// وکیل یکی از بازیکنانِ نیمه‌جان رو کامل به بازی برمی‌گردونه (حتی اگه
  /// عضوِ تیمِ سرکوب باشه)؛ بقیه‌ی نیمه‌جان‌ها همون‌لحظه به‌طورِ کامل و
  /// برای‌همیشه حذف می‌شن، و قابلیتِ وکیل برای بقیه‌ی بازی مصرف‌شده حساب می‌شه.
  void lawyerRevive(int targetId) {
    final lawyer = lawyerPlayer;
    if (!canLawyerReviveTonight || lawyer == null) return;
    final target = playerById(targetId);
    if (!target.isHalfAlive) return;

    final othersHalfAlive = players.where((p) => p.isHalfAlive && p.id != targetId).toList();

    target.isAlive = true;
    target.isHalfAlive = false;
    // اگه همین امشب (مثلاً خودحذفیِ مبارزِ انقلابی) تو لیستِ «حذف‌شده‌ها»
    // ثبت شده بود، دیگه واقعاً حذف نشده — از اون لیست درش می‌آریم تا تو
    // خلاصه‌ی صبح هم «حذف‌شده» هم «برگشته» حساب نشه.
    _tonightEliminatedIds.remove(target.id);
    _tonightRevivedId = target.id;

    for (final p in othersHalfAlive) {
      p.isHalfAlive = false; // حذفِ کامل و نهایی
    }

    lawyer.revivalUsed = true;
    notifyListeners();
  }

  /// نقطه‌ی مشترکِ همه‌ی حذف‌های «معمولی» (شات، اعدامِ انقلابی، رأی‌گیری،
  /// کلمه‌ی ممنوع): اگه وکیل هنوز قابلیتش رو مصرف نکرده، به‌جای حذفِ
  /// کامل، بازیکن نیمه‌جان می‌مونه. سلاخی از این تابع استفاده نمی‌کنه —
  /// همیشه مستقیم و بدون واسطه حذف می‌شه.
  void _eliminatePlayer(SessionPlayer player) {
    player.isAlive = false;
    player.isHalfAlive = hasUnusedPublicDefender;
    _checkZhinaTrigger(player);
    _skipDeadSpeakers();
  }

  /// اگه بازیکنِ حذف‌شده خودِ ژینا باشه، شبِ بعد تیمِ سرکوب هیچ قابلیتی
  /// نداره. سلاخی هم چون یه‌جور «حذف»ه، همین چک رو صدا می‌زنه، فقط جدا
  /// از _eliminatePlayer چون سلاخی مستقیم isAlive رو خودش ست می‌کنه.
  void _checkZhinaTrigger(SessionPlayer player) {
    if (player.roleId == SarkoobRoles.zhina.id) {
      sorkoobDisabledNextNight = true;
    }
  }

  // ---------- رپر معترض: عضوگیریِ شبانه برای مقاومت (مستقل از بقیه) ----------

  SessionPlayer? get rapperPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.rapper.id) return p;
    }
    return null;
  }

  List<SessionPlayer> get activeResistanceMembers =>
      players.where((p) => p.isActiveResistanceMember).toList();

  bool _rapperActedTonight = false;
  String? rapperResultMessage;

  bool get canRapperActTonight {
    final rapper = rapperPlayer;
    if (rapper == null || !_stillActiveTonight(rapper) || _rapperActedTonight) return false;
    return !isPlayerDetained(rapper.id);
  }

  /// نتیجه بر اساسِ تیم/نقشِ واقعیِ هدفه: شهروندِ ساده = عضوگیریِ موفق؛
  /// نقشی که هنوز طبقِ قانونِ «دیرهنگام‌بودنِ افشا»ش فعال نشده (مثلِ
  /// پرستوی نظام تو دو شبِ اول) = عضوگیریِ موفق ولی به‌عنوانِ جاسوس؛
  /// در غیرِاین‌صورت (سرکوبِ فعال یا تیمِ مستقل) = خودِ رپر حذف می‌شه.
  void rapperRecruit(int targetId) {
    final rapper = rapperPlayer;
    if (!canRapperActTonight || rapper == null) return;
    final target = playerById(targetId);
    final targetRole = target.roleId != null ? SarkoobRoles.byId(target.roleId!) : null;
    final isSleeperStillHidden = targetRole != null &&
        targetRole.investigationHiddenUntilNight > 0 &&
        roundNumber <= targetRole.investigationHiddenUntilNight;

    _rapperActedTonight = true;

    if (target.teamId == SarkoobTeams.citizen.id) {
      target.isActiveResistanceMember = true;
      rapperResultMessage = '«${target.name}» به تیمِ مقاومتِ فعال پیوست.';
    } else if (isSleeperStillHidden) {
      target.isActiveResistanceMember = true;
      rapperResultMessage =
          '«${target.name}» (که هنوز به‌عنوانِ سرکوب فعال نشده) به‌عنوانِ جاسوسِ سرکوب وارد مقاومت شد.';
    } else {
      _eliminatePlayer(rapper);
      rapperResultMessage = 'انتخاب اشتباه بود! خودِ «${rapper.name}» همون‌لحظه حذف شد.';
    }
    notifyListeners();
  }

  // ---------- شورشی: تقسیمِ اسلحه (شب) و شلیک (روز، مستقل از بقیه) ----------

  SessionPlayer? get rebelPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.rebel.id) return p;
    }
    return null;
  }

  bool get canRebelActTonight {
    final rebel = rebelPlayer;
    if (rebel == null || !_stillActiveTonight(rebel)) return false;
    return !isPlayerDetained(rebel.id);
  }

  /// آیا تا الان یه اسلحه‌ی جنگی به «نتیجه» رسیده — چه واقعاً شلیک شده چه
  /// گیرنده تا شروعِ رأی‌گیریِ فردا استفاده‌ش نکرده و خودش دستِ صاحبش
  /// منفجر شده (`startVoting`)؟ هر دو حالت «استفاده» حساب می‌شن، چون
  /// گیرنده فرصتِ یه روزِ کامل رو داشت. همین که یه‌بار این اتفاق بیفته،
  /// کارِ شورشی تمومه: دیگه هیچ شبی بیدار نمی‌شه (حتی با سهمیه‌ی بیشتر).
  /// استثنا: اگه گیرنده همون‌شبی که اسلحه رو گرفته از بازی خارج بشه (شات/
  /// سلاخی/اعدامِ انقلابی) و اصلاً به روزِ بعد نرسه، اصلاً فرصتی نداشته —
  /// این «استفاده» حساب نمی‌شه؛ اسلحه به سهمیه‌ی شورشی برمی‌گرده
  /// (`finishNight`ی پایینِ همین فایل) و می‌تونه شبِ دیگه به یکی دیگه بده.
  bool rebelWarGunUsed = false;

  /// یه اسلحه (جنگی یا مشقی) به یه بازیکن می‌ده. جنگی از سهمیه‌ی کلِ
  /// شورشی کم می‌شه؛ مشقی نامحدوده.
  void giveGun(int targetId, GunType type) {
    if (!canRebelActTonight) return;
    final rebel = rebelPlayer!;
    if (type == GunType.war) {
      if ((rebel.warGunsRemaining ?? 0) <= 0) return;
      rebel.warGunsRemaining = rebel.warGunsRemaining! - 1;
    }
    playerById(targetId).heldGunType = type;
    notifyListeners();
  }

  /// برای وقتی گرداننده اشتباهی اسلحه داده و می‌خواد پسش بگیره.
  void takeBackGun(int targetId) {
    final target = playerById(targetId);
    if (target.heldGunType == GunType.war) {
      final rebel = rebelPlayer;
      if (rebel != null) rebel.warGunsRemaining = (rebel.warGunsRemaining ?? 0) + 1;
    }
    target.heldGunType = null;
    notifyListeners();
  }

  /// بازیکنانی که همین الان اسلحه (هرنوعی) دستشونه و هنوز شلیک نکردن.
  List<SessionPlayer> get armedPlayers =>
      players.where((p) => p.isAlive && p.heldGunType != null).toList();

  String? gunFireResultMessage;
  String? gunExplosionSummary;

  /// اعلامِ اسلحه و شلیک — تویِ روز، تا قبل از شروعِ رأی‌گیری، توسطِ
  /// خودِ صاحبِ اسلحه (نه لزوماً شورشی).
  void fireGun(int shooterId, int targetId) {
    final shooter = playerById(shooterId);
    if (!shooter.isAlive || shooter.heldGunType == null) return;
    final type = shooter.heldGunType!;
    shooter.heldGunType = null;
    final target = playerById(targetId);

    if (type == GunType.war) {
      final teamName = SarkoobTeams.byId(target.teamId)?.name ?? target.teamId;
      _eliminatePlayer(target);
      rebelWarGunUsed = true;
      gunFireResultMessage =
          '«${target.name}» با شلیکِ «${shooter.name}» (اسلحه‌ی جنگی) از بازی خارج شد؛ تیمش: $teamName.';
    } else {
      gunFireResultMessage = '«${shooter.name}» شلیک کرد ولی اسلحه‌ش مشقی بود؛ هیچ اتفاقی نیفتاد.';
    }
    notifyListeners();
  }

  // ---------- قهرمان ملی: تضمین (مستقل از بقیه) ----------

  SessionPlayer? get nationalHeroPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.nationalHero.id) return p;
    }
    return null;
  }

  /// کسی که امروز تضمین شده (اگه کسی باشه) — رأی نمیاره و در امانه.
  int? guaranteedPlayerId;

  bool _heroActedTonight = false;

  bool get canGuaranteeTonight {
    final hero = nationalHeroPlayer;
    if (hero == null || !_stillActiveTonight(hero)) return false;
    if (isPlayerDetained(hero.id)) return false;
    if (_heroActedTonight) return false;
    return (hero.guaranteesRemaining ?? 0) > 0;
  }

  void guaranteePlayer(int targetId) {
    if (!canGuaranteeTonight) return;
    final hero = nationalHeroPlayer!;
    hero.guaranteesRemaining = (hero.guaranteesRemaining ?? 0) - 1;
    _heroActedTonight = true;
    guaranteedPlayerId = targetId;
    notifyListeners();
  }

  // ---------- دکتر: نجاتِ شبانه (مستقل از تصمیمِ رهبر و حکمِ اعدام) ----------

  SessionPlayer? get doctorPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.doctor.id) return p;
    }
    return null;
  }

  /// ظرفیتِ نجاتِ امشب: وابسته به تعدادِ زنده‌ی *همین الان*، پس هر شب و با
  /// هر مرگی، دوباره محاسبه می‌شه (طبق قانون: هر ۶ نفر یه نجاتِ بیشتر).
  int get doctorNightlyCapacity {
    final capacity = aliveCount ~/ 6;
    return capacity < 1 ? 1 : capacity;
  }

  List<SessionPlayer> get savedPlayersTonight => _savedPlayerIds.map(playerById).toList();

  bool get canDoctorSaveTonight {
    final doc = doctorPlayer;
    if (doc == null || !_stillActiveTonight(doc)) return false;
    if (isPlayerDetained(doc.id)) return false;
    return _doctorSavesUsedTonight < doctorNightlyCapacity;
  }

  /// آیا انتخابِ این هدفِ خاص الان مجازه؟ (اگه هدف خودِ دکتره، سقفِ
  /// نجاتِ‌خود در کلِ بازی رو هم چک می‌کنه)
  bool canDoctorSaveTarget(int targetId) {
    if (!canDoctorSaveTonight) return false;
    if (_savedPlayerIds.contains(targetId)) return false;
    final doc = doctorPlayer;
    if (doc != null && targetId == doc.id) {
      return doc.selfSavesUsed < settings.doctorMaxSelfSaves;
    }
    return true;
  }

  void doctorSave(int targetId) {
    if (!canDoctorSaveTarget(targetId)) return;
    final doc = doctorPlayer;
    if (doc != null && targetId == doc.id) {
      doc.selfSavesUsed++;
    }
    _savedPlayerIds.add(targetId);
    _doctorSavesUsedTonight++;
    notifyListeners();
  }

  /// برای وقتی گرداننده اشتباهی انتخاب کرده و می‌خواد برگردونه.
  void undoDoctorSave(int targetId) {
    if (!_savedPlayerIds.remove(targetId)) return;
    _doctorSavesUsedTonight--;
    final doc = doctorPlayer;
    if (doc != null && targetId == doc.id && doc.selfSavesUsed > 0) {
      doc.selfSavesUsed--;
    }
    notifyListeners();
  }

  void executePlayerForForbiddenWord(int playerId) {
    final player = playerById(playerId);
    _eliminatePlayer(player);
    // توجه: activeExecutionWord اینجا reset نمی‌شه — کلمه تا شروعِ رأی‌گیریِ
    // همون روز فعال می‌مونه (طبق قانون: هرکی بگتش، هر چندتا نفر که باشن،
    // حذف می‌شه). بستنِ پنجره فقط تو startVoting() انجام می‌شه.
    notifyListeners();
  }

  // ---------- هکر: استعلامِ شبانه (مستقل از بقیه‌ی نقش‌ها) ----------

  SessionPlayer? get hackerPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.hacker.id) return p;
    }
    return null;
  }

  bool _hackerUsedTonight = false;
  InvestigationResult? lastInvestigationResult;
  String? lastInvestigationTargetName;

  bool get canHackerInvestigateTonight {
    final hacker = hackerPlayer;
    if (hacker == null || !_stillActiveTonight(hacker) || _hackerUsedTonight) return false;
    return !isPlayerDetained(hacker.id);
  }

  /// نتیجه‌ی واقعیِ استعلام روی یه هدفِ خاص، طبقِ قوانینِ سناریو:
  /// همه‌ی اعضای واقعیِ سرکوب لایک می‌گیرن، به‌جز نقش‌هایی که همیشه بی‌گناه
  /// نشون داده می‌شن (ولی‌فقیه) یا چند شبِ اول هنوز جزوِ سرکوب دیده
  /// نمی‌شن (مثلِ پرستوی نظام، وقتی اضافه بشه). بقیه (شهروند، تیم‌های
  /// مستقل) همیشه دیس‌لایک می‌گیرن.
  InvestigationResult investigationResultFor(int targetId) {
    final target = playerById(targetId);
    final role = target.roleId != null ? SarkoobRoles.byId(target.roleId!) : null;
    final isSorkoobTeam = target.teamId == SarkoobTeams.suppression.id;

    if (!isSorkoobTeam) return InvestigationResult.dislike;
    if (role != null && role.alwaysShowsInnocent) return InvestigationResult.dislike;
    if (role != null &&
        role.investigationHiddenUntilNight > 0 &&
        roundNumber <= role.investigationHiddenUntilNight) {
      return InvestigationResult.dislike;
    }
    return InvestigationResult.like;
  }

  void hackerInvestigate(int targetId) {
    if (!canHackerInvestigateTonight) return;
    lastInvestigationResult = investigationResultFor(targetId);
    lastInvestigationTargetName = playerById(targetId).name;
    _hackerUsedTonight = true;
    notifyListeners();
  }

  // ---------- رهبرِ موساد: انتخابِ شیوه (شبِ اول) + عملیاتِ ترور/سری (شب‌های زوج) ----------

  SessionPlayer? get mossadLeaderPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.mossadLeader.id) return p;
    }
    return null;
  }

  /// شبِ اول تا شیوه رو انتخاب نکرده، نمی‌شه از این مرحله رد شد (اگه
  /// اصلاً رهبرِ موساد تو بازی نیست یا مرده — و امشب مرده حساب نمی‌شه اگه
  /// همین امشب سلاخی شده، چون تصمیمش هنوز نهایی نشده — چیزی برای
  /// انتخاب‌کردن نیست و همیشه می‌شه رد شد).
  bool get canAdvancePastMossadLeaderStep {
    final leader = mossadLeaderPlayer;
    if (leader == null || !_stillActiveTonight(leader)) return true;
    if (roundNumber != 1) return true;
    return leader.mossadPlaystyle != null;
  }

  void chooseMossadPlaystyle(MossadPlaystyle style) {
    final leader = mossadLeaderPlayer;
    if (leader == null || !_stillActiveTonight(leader) || roundNumber != 1) return;
    if (leader.mossadPlaystyle != null) return; // یه‌بار برای همیشه
    leader.mossadPlaystyle = style;
    notifyListeners();
  }

  /// آیا امشب هنوز از عملیاتِ ترور/سری استفاده نشده؟ (هرکدوم از
  /// mossadAssassinate/mossadShoot که یه‌بار استفاده بشه، امشب دیگه
  /// نمی‌شه عوضش کرد.)
  bool _mossadActedTonight = false;

  /// عملیاتِ ترور/سری فقط شب‌های زوجِ بازی (دوم، چهارم، ...) و فقط یک‌بار
  /// در هر شب قابل‌استفاده‌ست.
  bool get canMossadActTonight {
    final leader = mossadLeaderPlayer;
    if (leader == null || !_stillActiveTonight(leader) || leader.mossadPlaystyle == null) {
      return false;
    }
    if (roundNumber.isOdd) return false;
    if (_mossadActedTonight) return false;
    return !isPlayerDetained(leader.id);
  }

  String? mossadAssassinationResultMessage;

  /// عملیاتِ ترور: هدف + حدسِ نقش. فقط اگه هدف واقعاً عضوِ سرکوب باشه و
  /// نقشش درست حدس زده بشه حذف می‌شه — مثلِ سلاخی، مستقیم و برگشت‌ناپذیر
  /// (نه از تابعِ _eliminatePlayer که وکیل می‌تونه نجات بده)، و طبقِ همون
  /// قانون تو خلاصه‌ی دسته‌بندی‌شده‌ی صبح («🔪 سلاخی/ترور») هم می‌شینه.
  /// حدسِ غلط هیچ اثری تو بازی نداره و رهبرِ موساد به بقیه‌ی بازیکنا لو
  /// نمی‌ره — ولی نتیجه (موفق یا ناموفق) تو یادداشتِ خصوصیِ گرداننده
  /// می‌مونه، نه متنی که قراره عیناً به جمع خونده بشه.
  void mossadAssassinate(int targetId, String guessedRoleId) {
    if (!canMossadActTonight) return;
    final leader = mossadLeaderPlayer!;
    if (leader.mossadPlaystyle != MossadPlaystyle.assassination) return;
    _mossadActedTonight = true;
    final target = playerById(targetId);
    if (target.teamId == SarkoobTeams.suppression.id && target.roleId == guessedRoleId) {
      target.isAlive = false;
      target.eliminatedBySlaughter = true;
      _checkZhinaTrigger(target);
      _tonightSlaughteredIds.add(target.id);
      mossadAssassinationResultMessage = '«${target.name}» با ترورِ موساد از بازی خارج شد.';
    } else {
      mossadAssassinationResultMessage = 'ترورِ موساد بی‌اثر بود؛ هیچ‌کس متوجه نشد.';
    }
    notifyListeners();
  }

  /// عملیاتِ سری: مثلِ یه شاتِ ساده — صف‌بندی می‌شه تو همون _pendingHits ی
  /// شاتِ ولی‌فقیه، پس نجاتِ دکتر خودکار طبقِ همون قانونِ همیشگی روش اثر
  /// می‌ذاره و نتیجه‌ش هم خودکار تو خلاصه‌ی صبح («❌ کشته‌شدن») می‌شینه.
  void mossadShoot(int targetId) {
    if (!canMossadActTonight) return;
    final leader = mossadLeaderPlayer!;
    if (leader.mossadPlaystyle != MossadPlaystyle.secretOperation) return;
    _mossadActedTonight = true;
    _pendingHits[targetId] = (_pendingHits[targetId] ?? 0) + 1;
    notifyListeners();
  }

  // ---------- تحلیلگرِ سیاسی: استعلامِ عضویتِ تیمِ مستقل (شب‌های زوج) ----------

  SessionPlayer? get politicalAnalystPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.politicalAnalyst.id) return p;
    }
    return null;
  }

  bool _politicalAnalystUsedTonight = false;
  InvestigationResult? lastIndependentInvestigationResult;
  String? lastIndependentInvestigationTargetName;

  bool get canPoliticalAnalystActTonight {
    final analyst = politicalAnalystPlayer;
    if (analyst == null || !_stillActiveTonight(analyst) || _politicalAnalystUsedTonight) {
      return false;
    }
    if (roundNumber.isOdd) return false;
    return !isPlayerDetained(analyst.id);
  }

  /// آیا این بازیکن عضوِ یه تیمِ مستقله؟ (سرکوب و شهروند حساب نمی‌شن —
  /// فعلاً فقط موساد ممکنه، ولی جوری نوشته شده که با اضافه‌شدنِ تیمِ
  /// مستقلِ بعدی هم خودکار درست کار کنه.)
  bool _isIndependentTeamMember(SessionPlayer p) =>
      p.teamId != SarkoobTeams.suppression.id && p.teamId != SarkoobTeams.citizen.id;

  void politicalAnalystInvestigate(int targetId) {
    if (!canPoliticalAnalystActTonight) return;
    final target = playerById(targetId);
    lastIndependentInvestigationResult = _isIndependentTeamMember(target)
        ? InvestigationResult.like
        : InvestigationResult.dislike;
    lastIndependentInvestigationTargetName = target.name;
    _politicalAnalystUsedTonight = true;
    notifyListeners();
  }

  // ---------- فعال مدنی: درخواستِ رفراندوم (شبانه، یک‌بارمصرف) ----------

  SessionPlayer? get civicActivistPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.civicActivist.id) return p;
    }
    return null;
  }

  bool get canRequestReferendumTonight {
    final activist = civicActivistPlayer;
    if (activist == null || !_stillActiveTonight(activist) || activist.referendumUsed) {
      return false;
    }
    return !isPlayerDetained(activist.id);
  }

  bool _referendumRequestedThisNight = false;

  /// امروز (روزِ بلافاصله بعدِ درخواست)، قبل از رأی‌گیریِ حذف، رفراندوم
  /// برگزار می‌شه. تویِ moveToDay ست می‌شه اگه دیشب درخواست شده باشه.
  bool referendumScheduledToday = false;

  void requestReferendum() {
    if (!canRequestReferendumTonight) return;
    civicActivistPlayer!.referendumUsed = true;
    _referendumRequestedThisNight = true;
    notifyListeners();
  }

  // ---------- اجرای رفراندوم (روزِ بعد، قبل از رأی‌گیریِ حذف) ----------

  final Map<int, int> _referendumVotes = {}; // playerId -> تعداد رأی برای رهبریِ جامعه

  /// null یعنی همه‌ی بازیکنانِ زنده کاندیدان؛ بعدِ یه تساوی، فقط همون
  /// نامزدهای مساوی می‌مونن — دقیقاً مثلِ دورِ دومِ رأی‌گیریِ عادی که
  /// فقط بینِ نفراتِ دفاعیه‌ست.
  List<int>? _referendumCandidateIds;
  int? communityLeaderId;
  String? communityLeaderExpulsionMessage;

  List<SessionPlayer> get referendumCandidates => _referendumCandidateIds == null
      ? alivePlayers
      : _referendumCandidateIds!.map((id) => playerById(id)).toList();

  /// آیا الان تو دورِ محدودشده‌ایم (یعنی دورِ قبلی مساوی شده بود)؟
  bool get isReferendumRunoff => _referendumCandidateIds != null;

  int referendumVotesFor(int playerId) => _referendumVotes[playerId] ?? 0;

  /// رأی‌گیریِ رفراندوم علنیه (از سرِ نوبتِ صحبت، یکی‌یکی) — گرداننده فقط
  /// با +/- شمارش می‌کنه، مثلِ رأی‌گیریِ عادی.
  void castReferendumVote(int candidateId, int delta) {
    final current = _referendumVotes[candidateId] ?? 0;
    final updated = current + delta;
    _referendumVotes[candidateId] = updated < 0 ? 0 : updated;
    notifyListeners();
  }

  /// نامزد(هایی) که الان بیشترین رأی رو دارن.
  List<SessionPlayer> get referendumLeadingCandidates {
    if (_referendumVotes.isEmpty) return [];
    final maxVotes = _referendumVotes.values.reduce((a, b) => a > b ? a : b);
    if (maxVotes <= 0) return [];
    return _referendumVotes.entries
        .where((e) => e.value == maxVotes)
        .map((e) => playerById(e.key))
        .toList();
  }

  /// دکمه‌ی «پایانِ رأی‌گیری»: اگه یه برنده‌ی روشن هست، همون رهبرِ جامعه
  /// می‌شه. اگه چندتا نامزد مساوی بیشترین رأی رو داشتن، دورِ بعدی محدود
  /// می‌شه به فقط همین‌ها و رأی‌گیری از صفر شروع می‌شه — دقیقاً مثلِ
  /// دورِ دومِ رأی‌گیریِ عادی (نه انتخابِ دستیِ گرداننده).
  void resolveReferendumRound() {
    final leading = referendumLeadingCandidates;
    if (leading.isEmpty) return;
    if (leading.length == 1) {
      confirmCommunityLeader(leading.first.id);
      return;
    }
    _referendumCandidateIds = leading.map((p) => p.id).toList();
    _referendumVotes.clear();
    notifyListeners();
  }

  void confirmCommunityLeader(int playerId) {
    communityLeaderId = playerId;
    notifyListeners();
  }

  /// رهبرِ جامعه بلافاصله یه نفر رو اخراج می‌کنه — قطعی و برگشت‌ناپذیر،
  /// حتی اگه وکیل هنوز استفاده نشده باشه (مثلِ اخراجِ انضباطی/ترورِ
  /// مزدور، نه از تابعِ _eliminatePlayer). بعدش رفراندوم تموم می‌شه و
  /// روالِ عادیِ رأی‌گیریِ همون روز از سر گرفته می‌شه.
  void communityLeaderExpel(int targetId) {
    if (communityLeaderId == null) return;
    final leader = playerById(communityLeaderId!);
    final target = playerById(targetId);
    if (!target.isAlive) return;
    final teamName = SarkoobTeams.byId(target.teamId)?.name ?? target.teamId;
    target.isAlive = false;
    target.isHalfAlive = false;
    _checkZhinaTrigger(target);
    _skipDeadSpeakers();
    communityLeaderExpulsionMessage =
        '«${target.name}» توسطِ رهبرِ جامعه («${leader.name}») از جامعه اخراج شد؛ تیمش: $teamName.';

    referendumScheduledToday = false;
    communityLeaderId = null;
    _referendumVotes.clear();
    _referendumCandidateIds = null;
    notifyListeners();
  }

  // ---------- مبارزِ انقلابی: اعدامِ انقلابی/سلاخی (مستقل از بقیه) ----------

  SessionPlayer? get revolutionaryFighterPlayer {
    for (final p in players) {
      if (p.roleId == SarkoobRoles.revolutionaryFighter.id) return p;
    }
    return null;
  }

  bool _revolutionaryActedTonight = false;
  String? revolutionaryResultMessage;

  bool get canRevolutionaryActTonight {
    final fighter = revolutionaryFighterPlayer;
    if (fighter == null || !_stillActiveTonight(fighter)) return false;
    if (_revolutionaryActedTonight) return false;
    if (isPlayerDetained(fighter.id)) return false;
    return (fighter.revolutionaryChargesRemaining ?? 0) > 0;
  }

  /// اعدامِ انقلابی: نتیجه به تیمِ هدف بستگی داره — عضوِ سرکوب مثلِ شاتِ
  /// شبانه یه ضربه می‌خوره (زره/نجاتِ دکتر طبقِ قانونِ خودشون اثر می‌ذارن)،
  /// عضوِ تیمِ مستقل بی‌اثره، و عضوِ تیمِ شهروند باعثِ حذفِ خودِ مبارز می‌شه.
  void revolutionaryExecute(int targetId) {
    final fighter = revolutionaryFighterPlayer;
    if (!canRevolutionaryActTonight || fighter == null) return;
    final target = playerById(targetId);

    fighter.revolutionaryChargesRemaining = (fighter.revolutionaryChargesRemaining ?? 0) - 1;
    _revolutionaryActedTonight = true;

    if (target.teamId == SarkoobTeams.suppression.id) {
      _pendingHits[targetId] = (_pendingHits[targetId] ?? 0) + 1;
      revolutionaryResultMessage =
          'اعدامِ انقلابیِ «${fighter.name}» روی «${target.name}» ثبت شد؛ نتیجه‌ی نهایی صبح مشخص می‌شه.';
    } else if (target.teamId == SarkoobTeams.citizen.id) {
      _eliminatePlayer(fighter);
      _tonightEliminatedIds.add(fighter.id);
      revolutionaryResultMessage =
          'هدفِ «${fighter.name}» عضوِ تیمِ شهروند بود! خودِ مبارزِ انقلابی همون‌لحظه از بازی خارج شد.';
    } else {
      revolutionaryResultMessage = 'هدفِ «${fighter.name}» عضوِ یه تیمِ مستقل بود؛ هیچ اتفاقی نیفتاد.';
    }
    notifyListeners();
  }

  /// سلاخی: درست حدس‌زدن = حذفِ فوری و غیرقابل‌برگشت (نه دکتر نه وکیل
  /// مردمی نمی‌تونن جلوشو بگیرن). غلط حدس‌زدن = فقط قابلیتِ سلاخی برای
  /// همیشه از دست می‌ره (اعدامِ انقلابی هنوز باقیه).
  void revolutionarySlaughter(int targetId, String guessedRoleId) {
    final fighter = revolutionaryFighterPlayer;
    if (!canRevolutionaryActTonight || fighter == null || !fighter.canStillSlaughter) return;
    final target = playerById(targetId);
    final correct = target.roleId == guessedRoleId;

    fighter.revolutionaryChargesRemaining = (fighter.revolutionaryChargesRemaining ?? 0) - 1;
    _revolutionaryActedTonight = true;

    if (correct) {
      target.isAlive = false;
      target.eliminatedBySlaughter = true;
      _checkZhinaTrigger(target);
      _tonightSlaughteredIds.add(target.id);
      revolutionaryResultMessage = '«${target.name}» با سلاخیِ مبارزِ انقلابی از بازی خارج شد.';
    } else {
      fighter.canStillSlaughter = false;
      revolutionaryResultMessage =
          'حدسِ «${fighter.name}» غلط بود؛ دیگه هرگز نمی‌تونه سلاخی کنه.';
    }
    notifyListeners();
  }

  // ---------- ترتیبِ بیدارشدنِ شب ----------

  static const List<NightStepKind> _nightStepOrder = [
    NightStepKind.sorkoobTeam,
    NightStepKind.mafiaTeam,
    NightStepKind.mossadLeader,
    NightStepKind.rapper,
    NightStepKind.hacker,
    NightStepKind.politicalAnalyst,
    NightStepKind.doctor,
    NightStepKind.rebel,
    NightStepKind.nationalHero,
    NightStepKind.revolutionary,
    NightStepKind.civicActivist,
    NightStepKind.lawyer,
    NightStepKind.done,
  ];

  NightStepKind currentNightStep = NightStepKind.sorkoobTeam;

  /// آیا این مرحله باید تو ترتیبِ شب بیاد؟ نکته‌ی مهم: مرده‌بودنِ صاحبِ
  /// نقش دلیلِ کافی برای ردکردنِ مرحله نیست — اگه هکر/دکتر/مبارز مرده
  /// باشن هم بازم باید صداشون بزنیم (فقط دکمه‌هاشون غیرفعاله)، وگرنه
  /// حذف‌شدنِ خودِ مرحله از ترتیبِ شب لو می‌ده که اون نقش مرده. سه‌تا
  /// استثنا داریم — هرکدوم چون همه از قبل (تویِ روز) با خبر شدن، پس دیگه
  /// لازم نیست تو ترتیب بیان: وکیل، وقتی قابلیتش رو علنی مصرف کرد (یکی
  /// رو برگردوند)؛ شورشی، وقتی یکی از اسلحه‌های جنگیش عملاً به‌نتیجه‌رسیده؛
  /// فعال مدنی، وقتی درخواستِ رفراندومش رو مصرف کرده. جدا از اون‌ها،
  /// رهبرِ موساد و تحلیلگرِ سیاسی هم فقط شب‌های خاصی (اولی هم شبِ اول هم
  /// زوج، دومی فقط زوج) وارد ترتیب می‌شن — این یه قاعده‌ی عمومی و از قبل
  /// مشخصِ خودِ نقشه، نه چیزی که لو بده کسی زنده یا مرده‌ست.
  bool _isNightStepApplicable(NightStepKind step) {
    switch (step) {
      case NightStepKind.sorkoobTeam:
        // فقط تو سناریوی سرکوب معنی داره؛ تو یه بازیِ سناریوی مافیا هیچ
        // بازیکنی این تیم رو نداره، پس این مرحله کلاً رد می‌شه.
        return players.any((p) => p.teamId == SarkoobTeams.suppression.id);
      case NightStepKind.mafiaTeam:
        // آینه‌ی همون منطق، برای سناریوی مافیا.
        return players.any((p) => p.teamId == SarkoobTeams.mafiaGang.id);
      case NightStepKind.mossadLeader:
        // شبِ اول (برای انتخابِ شیوه) یا شب‌های زوج (برای استفاده). فردِ
        // مرده هم باز باید صداش کنیم (لوندادن)، پس isAlive رو چک نمی‌کنیم.
        if (mossadLeaderPlayer == null) return false;
        return roundNumber == 1 || roundNumber.isEven;
      case NightStepKind.rapper:
        return rapperPlayer != null;
      case NightStepKind.hacker:
        return hackerPlayer != null;
      case NightStepKind.politicalAnalyst:
        if (politicalAnalystPlayer == null) return false;
        return roundNumber.isEven;
      case NightStepKind.doctor:
        return doctorPlayer != null;
      case NightStepKind.rebel:
        return rebelPlayer != null && !rebelWarGunUsed;
      case NightStepKind.nationalHero:
        return nationalHeroPlayer != null;
      case NightStepKind.revolutionary:
        return revolutionaryFighterPlayer != null;
      case NightStepKind.civicActivist:
        final activist = civicActivistPlayer;
        return activist != null && !activist.referendumUsed;
      case NightStepKind.lawyer:
        final l = lawyerPlayer;
        return l != null && !l.revivalUsed;
      case NightStepKind.done:
        return true;
    }
  }

  /// آیا الان نوبتِ اعضای سرکوبه که به‌جای ولی‌فقیه، تصمیمِ شاتِ معمولی
  /// (نه سلاخی) رو بگیرن؟ همین که ولی‌فقیه از بازی خارج بشه صادقه — چه
  /// بقیه‌ی نقش‌دارهای سرکوب (وزیر امور خارجه، رئیس قوه قضاییه و...) زنده
  /// باشن چه نه. سلاخی مخصوصِ خودِ ولی‌فقیه‌ست و با مرگش از بین می‌ره، ولی
  /// شاتِ تیمی هیچ‌وقت کاملاً از دست نمی‌ره، مادامی که حداقل یه عضوِ زنده
  /// از تیمِ سرکوب باقی باشه.
  bool get canFallbackShoot {
    if (sorkoobDisabledTonight) return false;
    final leader = valiFaghihPlayer;
    if (leader != null && leader.isAlive) return false;
    return alivePlayers.any((p) => p.teamId == SarkoobTeams.suppression.id);
  }

  /// آیا الان می‌شه از مرحله‌ی «تیمِ سرکوب» جلوتر رفت؟ اگه ولی‌فقیه زنده‌ست،
  /// باید حتماً تصمیمش رو گرفته باشه (شات/سلاخی/مذاکره)؛ اگه زنده نیست ولی
  /// بازم شاتِ جایگزین ممکنه، بازم باید یه تصمیم گرفته شده باشه؛ فقط وقتی
  /// کلِ تیمِ سرکوب حذف شده، بدونِ هیچ تصمیمی هم می‌شه رد شد.
  bool get canAdvancePastSorkoobTeamStep {
    if (sorkoobDisabledTonight) return true;
    final leader = valiFaghihPlayer;
    final leaderAlive = leader != null && leader.isAlive;
    if (leaderAlive) return _nightActionTaken;
    if (canFallbackShoot) return _nightActionTaken;
    return true;
  }

  void advanceNightStep() {
    var idx = _nightStepOrder.indexOf(currentNightStep) + 1;
    if (idx >= _nightStepOrder.length) return; // از قبل تهِ لیست بودیم
    while (idx < _nightStepOrder.length - 1 && !_isNightStepApplicable(_nightStepOrder[idx])) {
      idx++;
    }
    currentNightStep = _nightStepOrder[idx];
    notifyListeners();
  }

  // ---------- پایانِ شب ----------

  void moveToNight(int nightNumber) {
    _phaseHistory.add(_PhaseSnapshot(phase, roundNumber));
    phase = GamePhaseType.night;
    roundNumber = nightNumber;
    _pendingHits.clear();
    _savedPlayerIds.clear();
    _doctorSavesUsedTonight = 0;
    _hackerUsedTonight = false;
    _mossadActedTonight = false;
    lastInvestigationResult = null;
    lastInvestigationTargetName = null;
    _revolutionaryActedTonight = false;
    revolutionaryResultMessage = null;
    _rapperActedTonight = false;
    rapperResultMessage = null;
    _intelQuestionUsedTonight = false;
    lastIntelQuestionResult = null;
    lastIntelQuestionTargetNames = null;
    _heroActedTonight = false;
    guaranteedPlayerId = null; // تضمینِ دیروز فقط برای همون روز بود، الان منقضی می‌شه
    _detainedLastNight = detainedPlayerId; // دیشب کی بازداشت بود، برای قانونِ «نه دو شبِ پیاپی»
    detainedPlayerId = null;
    sorkoobDisabledTonight = sorkoobDisabledNextNight;
    sorkoobDisabledNextNight = false;
    _nightActionTaken = false;
    slaughterResultMessage = null;
    negotiateResultMessage = null;
    lastNightSummary = null;
    nightPrivateNotes = null;
    statusInquiryVoteOpen = false;
    statusInquiryYesVotes = 0;
    statusInquiryLastVotePassed = null;
    statusInquiryResultMessage = null;
    _tonightSlaughteredIds.clear();
    _tonightEliminatedIds.clear();
    _tonightRevivedId = null;
    mossadAssassinationResultMessage = null;
    _politicalAnalystUsedTonight = false;
    lastIndependentInvestigationResult = null;
    lastIndependentInvestigationTargetName = null;
    _referendumRequestedThisNight = false;
    currentNightStep =
        _nightStepOrder.firstWhere(_isNightStepApplicable, orElse: () => NightStepKind.done);
    notifyListeners();
  }

  /// این متن همونیه که گرداننده باید عیناً و بصورتِ عمومی به جمع اعلام
  /// کنه: فقط سه دسته — سلاخی/ترور، کشته‌شدن، بازگشت به بازی. هیچ جزئیاتِ
  /// دیگه‌ای (چرا، با چه نقشی، مذاکره موفق بود یا نه، زره شکست یا نه)
  /// اینجا نمیاد، چون اونا اطلاعاتِ راهبردی‌ان که نباید علنی بشن.
  String? lastNightSummary;

  /// یادداشتِ خصوصیِ گرداننده — همون جزئیاتِ بالا، فقط برای خودِ گرداننده
  /// و هیچ‌وقت برای اعلامِ عمومی. جدا از lastNightSummary نگه داشته می‌شه
  /// تا تو UI هم واضح متمایز نشون داده بشن.
  String? nightPrivateNotes;

  /// پایانِ شب: ضربه‌های شات رو با نجاتِ دکتر، زره‌ی معمولی، و زرهِ
  /// همیشگیِ رهبرِ موساد حل‌وفصل می‌کنه، و دو تا خلاصه‌ی جدا می‌سازه: یکی
  /// برای اعلامِ عمومی (سه دسته‌ی ثابت)، یکی برای یادداشتِ خصوصیِ گرداننده.
  void finishNight() {
    final privateNotes = <String>[];
    _pendingHits.forEach((targetId, hitCount) {
      final target = playerById(targetId);
      if (!target.isAlive) return;
      var remaining = hitCount;
      if (_savedPlayerIds.contains(targetId) && remaining > 0) {
        remaining -= 1; // نجاتِ دکتر فقط جلوی یکی از ضربه‌ها رو می‌گیره
      }
      if (remaining <= 0) return;
      final targetRole = target.roleId != null ? SarkoobRoles.byId(target.roleId!) : null;
      if (targetRole?.hasPermanentNightArmor == true) {
        // رهبرِ موساد: زره‌ش هیچ‌وقت مصرف نمی‌شه، پس هر تعداد ضربه‌ی شات
        // هم باشه، امشب زنده می‌مونه.
        privateNotes.add('«${target.name}» (رهبرِ موساد) با زره‌ی همیشگی‌ش شاتِ شب رو خنثی کرد.');
        return;
      }
      if (target.hasArmor) {
        target.hasArmor = false;
        remaining -= 1;
      }
      if (remaining > 0) {
        _eliminatePlayer(target);
        _tonightEliminatedIds.add(target.id);
      } else {
        privateNotes.add('«${target.name}» زره‌اش رو از دست داد، ولی زنده موند.');
      }
    });

    // اگه کسی که امشب اسلحه‌ی جنگی گرفته بود اصلاً به روزِ بعد نرسید (شات/
    // سلاخی/اعدامِ انقلابی — هرکدوم)، فرصتِ استفاده نداشت. این «استفاده»
    // حساب نمی‌شه: اسلحه به سهمیه‌ی شورشی برمی‌گرده تا شبِ دیگه به یکی
    // دیگه بده، و rebelWarGunUsed دست‌نخورده می‌مونه.
    for (final p in players) {
      if (!p.isAlive && p.heldGunType == GunType.war) {
        final rebel = rebelPlayer;
        if (rebel != null) rebel.warGunsRemaining = (rebel.warGunsRemaining ?? 0) + 1;
        p.heldGunType = null;
      }
    }

    if (slaughterResultMessage != null) privateNotes.insert(0, slaughterResultMessage!);
    if (negotiateResultMessage != null) privateNotes.insert(0, negotiateResultMessage!);
    if (revolutionaryResultMessage != null) privateNotes.insert(0, revolutionaryResultMessage!);
    if (rapperResultMessage != null) privateNotes.insert(0, rapperResultMessage!);
    if (mossadAssassinationResultMessage != null) {
      privateNotes.insert(0, mossadAssassinationResultMessage!);
    }

    final announcement = <String>[];
    if (_tonightSlaughteredIds.isNotEmpty) {
      final names = _tonightSlaughteredIds.map((id) => playerById(id).name).join('، ');
      announcement.add('🔪 با سلاخی/ترور از بازی خارج شدن: $names');
    }
    if (_tonightEliminatedIds.isNotEmpty) {
      final names = _tonightEliminatedIds.map((id) => playerById(id).name).join('، ');
      announcement.add('❌ کشته شدن: $names');
    }
    if (_tonightRevivedId != null) {
      announcement.add('✅ برگشتن به بازی: ${playerById(_tonightRevivedId!).name}');
    }

    lastNightSummary =
        announcement.isEmpty ? 'دیشب هیچ‌کس از بازی خارج نشد و هیچ‌کس هم برنگشت.' : announcement.join('\n');
    nightPrivateNotes = privateNotes.isEmpty ? null : privateNotes.join('\n');
    _pendingHits.clear();
    _savedPlayerIds.clear();
    notifyListeners();
  }
}
