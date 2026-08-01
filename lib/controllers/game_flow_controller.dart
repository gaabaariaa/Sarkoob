import 'package:flutter/foundation.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';

/// نتیجه‌ی نهاییِ حل‌وفصلِ رأی‌گیریِ یه روز.
class VoteResolution {
  final String message;
  const VoteResolution(this.message);
}

/// ترتیبِ «بیدارشدنِ» شب: اول تیمِ سرکوب باهم، بعد هر نقشِ خاصِ شهروندی
/// جداگونه و به‌ترتیب، و در آخر جمع‌بندیِ شب.
enum NightStepKind { sorkoobTeam, hacker, doctor, revolutionary, lawyer, done }

/// موتور اصلی «گردانندگی» یه جلسه‌ی بازی: ترتیب صحبت، چالش، رأی‌گیری،
/// دفاعیه، حذف، و شب (تصمیمِ رهبر سرکوب، مذاکره، حکم اعدام).
class GameFlowController extends ChangeNotifier {
  final List<SessionPlayer> players;
  GameSettings settings;

  GamePhaseType phase = GamePhaseType.introDay;
  int roundNumber = 0;

  GameFlowController({required this.players, required this.settings}) {
    _rebuildSpeakingOrder();
  }

  List<SessionPlayer> get alivePlayers => players.where((p) => p.isAlive).toList();

  SessionPlayer playerById(int id) => players.firstWhere((p) => p.id == id);

  int get aliveCount => alivePlayers.length;
  int get majorityThreshold => (aliveCount / 2).ceil();

  // ---------- ترتیب صحبت ----------

  List<int> _speakingOrder = [];
  int _speakerPointer = 0;

  void _rebuildSpeakingOrder() {
    _speakingOrder = alivePlayers.map((p) => p.id).toList();
    _speakerPointer = 0;
    for (final p in players) {
      p.hasSpokenThisRound = false;
      p.challengeUsedToday = false;
    }
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
    notifyListeners();
  }

  /// بازیکن‌هایی که الان می‌تونن چالش بگیرن (فقط توی روزهای عادی)
  List<SessionPlayer> get challengeEligiblePlayers {
    if (phase != GamePhaseType.day) return const [];
    return alivePlayers
        .where((p) => !p.challengeUsedToday && p.id != speakerForDisplay?.id)
        .toList();
  }

  /// یه بازیکن چالش می‌گیره؛ بعدش نوبتِ عادی دست‌نخورده می‌مونه.
  void useChallenge(int challengerId) {
    final challenger = playerById(challengerId);
    challenger.challengeUsedToday = true;
    _activeChallengerId = challengerId;
    notifyListeners();
  }

  void finishChallenge() {
    _activeChallengerId = null;
    notifyListeners();
  }

  // ---------- انتقال بین فازها ----------

  void moveToIntroNight() {
    phase = GamePhaseType.introNight;
    notifyListeners();
  }

  void moveToDay(int dayNumber) {
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
    if (pendingExecutionWord != null) {
      activeExecutionWord = pendingExecutionWord;
      pendingExecutionWord = null;
    }
    notifyListeners();
  }

  // ---------- رأی‌گیری دور اول ----------

  bool votingStarted = false;

  void startVoting() {
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
        .where((p) => p.votes >= majorityThreshold)
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
  String? lastNightSummary;

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

  /// شهروندهای «خاکستری»: زنده، عضو تیم شهروند، و بدون نقشِ خاص.
  List<SessionPlayer> get grayCitizens => players
      .where((p) => p.isAlive && p.teamId == SarkoobTeams.citizen.id && p.roleId == null)
      .toList();

  bool get canUseNegotiate {
    final minister = foreignMinisterPlayer;
    if (minister == null || !minister.isAlive) return false;
    if (!sorkoobHasLostMember) return false;
    if (grayCitizens.isEmpty) return false;
    return true;
  }

  void leaderNegotiate(int targetId) {
    final target = playerById(targetId);
    final isGrayCitizen = target.teamId == SarkoobTeams.citizen.id && target.roleId == null;
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
    _pendingHits[targetId] = (_pendingHits[targetId] ?? 0) + 1;
    _nightActionTaken = true;
    notifyListeners();
  }

  void leaderSlaughter(int targetId, String guessedRoleId) {
    final leader = valiFaghihPlayer;
    if (leader == null) return;
    final target = playerById(targetId);
    final correct = target.roleId == guessedRoleId;
    if (correct) {
      target.isAlive = false;
      target.eliminatedBySlaughter = true;
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
    final chief = judiciaryChiefPlayer;
    return chief != null && chief.isAlive && !chief.executionOrderUsed;
  }

  void issueExecutionOrder(String word) {
    final chief = judiciaryChiefPlayer;
    if (chief == null) return;
    chief.executionOrderUsed = true;
    pendingExecutionWord = word.trim();
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
    return lawyer != null && lawyer.isAlive && !lawyer.revivalUsed;
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
    if (doc == null || !doc.isAlive) return false;
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
    return hacker != null && hacker.isAlive && !_hackerUsedTonight;
  }

  /// نتیجه‌ی واقعیِ استعلام روی یه هدفِ خاص، طبقِ قوانینِ سناریو:
  /// همه‌ی اعضای واقعیِ سرکوب لایک می‌گیرن، به‌جز نقش‌هایی که همیشه بی‌گناه
  /// نشون داده می‌شن (ولی‌فقیه) یا چند شبِ اول هنوز جزوِ سرکوب دیده
  /// نمی‌شن (مثلِ سلبریتی حکومتی، وقتی اضافه بشه). بقیه (شهروند، تیم‌های
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
    if (fighter == null || !fighter.isAlive) return false;
    if (_revolutionaryActedTonight) return false;
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
    NightStepKind.hacker,
    NightStepKind.doctor,
    NightStepKind.revolutionary,
    NightStepKind.lawyer,
    NightStepKind.done,
  ];

  NightStepKind currentNightStep = NightStepKind.sorkoobTeam;

  /// آیا این مرحله اصلاً امشب معنی داره؟ (نقش وجود داره و زنده‌ست، وگرنه
  /// رد می‌شه بدون این‌که اصلاً نشون داده بشه)
  /// آیا این مرحله باید تو ترتیبِ شب بیاد؟ نکته‌ی مهم: مرده‌بودنِ صاحبِ
  /// نقش دلیلِ کافی برای ردکردنِ مرحله نیست — اگه هکر/دکتر/مبارز مرده
  /// باشن هم بازم باید صداشون بزنیم (فقط دکمه‌هاشون غیرفعاله)، وگرنه
  /// حذف‌شدنِ خودِ مرحله از ترتیبِ شب لو می‌ده که اون نقش مرده. فقط وکیل
  /// استثناست: وقتی قابلیتش رو علنی مصرف کرد (یکی رو برگردوند)، همه از
  /// قبل فهمیدن، پس دیگه لازم نیست تو ترتیب بیاد.
  bool _isNightStepApplicable(NightStepKind step) {
    switch (step) {
      case NightStepKind.sorkoobTeam:
        return true;
      case NightStepKind.hacker:
        return hackerPlayer != null;
      case NightStepKind.doctor:
        return doctorPlayer != null;
      case NightStepKind.revolutionary:
        return revolutionaryFighterPlayer != null;
      case NightStepKind.lawyer:
        final l = lawyerPlayer;
        return l != null && !l.revivalUsed;
      case NightStepKind.done:
        return true;
    }
  }

  /// آیا الان می‌شه از مرحله‌ی «تیمِ سرکوب» جلوتر رفت؟ اگه ولی‌فقیه زنده‌ست،
  /// باید حتماً تصمیمش رو گرفته باشه (شات/سلاخی/مذاکره)؛ اگه زنده نیست،
  /// همیشه می‌شه رد شد (مذاکره اختیاریه).
  bool get canAdvancePastSorkoobTeamStep {
    final leader = valiFaghihPlayer;
    final leaderAlive = leader != null && leader.isAlive;
    if (!leaderAlive) return true;
    return _nightActionTaken;
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
    phase = GamePhaseType.night;
    roundNumber = nightNumber;
    currentNightStep = NightStepKind.sorkoobTeam;
    _pendingHits.clear();
    _savedPlayerIds.clear();
    _doctorSavesUsedTonight = 0;
    _hackerUsedTonight = false;
    lastInvestigationResult = null;
    lastInvestigationTargetName = null;
    _revolutionaryActedTonight = false;
    revolutionaryResultMessage = null;
    _nightActionTaken = false;
    slaughterResultMessage = null;
    negotiateResultMessage = null;
    lastNightSummary = null;
    notifyListeners();
  }

  void finishNight() {
    final messages = <String>[];
    _pendingHits.forEach((targetId, hitCount) {
      final target = playerById(targetId);
      if (!target.isAlive) return;
      var remaining = hitCount;
      if (_savedPlayerIds.contains(targetId) && remaining > 0) {
        remaining -= 1; // نجاتِ دکتر فقط جلوی یکی از ضربه‌ها رو می‌گیره
      }
      if (remaining <= 0) return;
      if (target.hasArmor) {
        target.hasArmor = false;
        remaining -= 1;
      }
      if (remaining > 0) {
        _eliminatePlayer(target);
        messages.add('«${target.name}» شبِ گذشته حذف شد.');
      } else {
        messages.add('«${target.name}» زره‌اش رو از دست داد، ولی زنده موند.');
      }
    });
    if (slaughterResultMessage != null) messages.insert(0, slaughterResultMessage!);
    if (negotiateResultMessage != null) messages.insert(0, negotiateResultMessage!);
    if (revolutionaryResultMessage != null) messages.insert(0, revolutionaryResultMessage!);
    lastNightSummary = messages.isEmpty ? 'دیشب کسی حذف نشد.' : messages.join('\n');
    _pendingHits.clear();
    _savedPlayerIds.clear();
    notifyListeners();
  }
}
