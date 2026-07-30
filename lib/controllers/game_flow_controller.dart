import 'package:flutter/foundation.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';

/// نتیجه‌ی نهاییِ حل‌وفصلِ رأی‌گیریِ یه روز.
class VoteResolution {
  final String message;
  const VoteResolution(this.message);
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
        only.isAlive = false;
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
        eliminated.isAlive = false;
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

  /// آیا الان «وکیل مردمی» هست که هنوز قابلیتش رو مصرف نکرده؟ این نقش
  /// هنوز تعریف نشده، پس فعلاً همیشه false برمی‌گرده تا وقتی اضافه بشه.
  bool get hasUnusedPublicDefender => false; // TODO: وقتی «وکیل مردمی» اضافه شد این رو کامل کن

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
    if (hasUnusedPublicDefender) {
      player.isAlive = false;
      player.isHalfAlive = true;
    } else {
      player.isAlive = false;
    }
    // توجه: activeExecutionWord اینجا reset نمی‌شه — کلمه تا شروعِ رأی‌گیریِ
    // همون روز فعال می‌مونه (طبق قانون: هرکی بگتش، هر چندتا نفر که باشن،
    // حذف می‌شه). بستنِ پنجره فقط تو startVoting() انجام می‌شه.
    notifyListeners();
  }

  // ---------- پایانِ شب ----------

  void moveToNight(int nightNumber) {
    phase = GamePhaseType.night;
    roundNumber = nightNumber;
    _pendingHits.clear();
    _savedPlayerIds.clear();
    _doctorSavesUsedTonight = 0;
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
        target.isAlive = false;
        messages.add('«${target.name}» شبِ گذشته حذف شد.');
      } else {
        messages.add('«${target.name}» زره‌اش رو از دست داد، ولی زنده موند.');
      }
    });
    if (slaughterResultMessage != null) messages.insert(0, slaughterResultMessage!);
    if (negotiateResultMessage != null) messages.insert(0, negotiateResultMessage!);
    lastNightSummary = messages.isEmpty ? 'دیشب کسی حذف نشد.' : messages.join('\n');
    _pendingHits.clear();
    _savedPlayerIds.clear();
    notifyListeners();
  }
}
