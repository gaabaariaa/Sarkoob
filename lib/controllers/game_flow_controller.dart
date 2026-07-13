import 'package:flutter/foundation.dart';
import '../models/game_session.dart';

/// نتیجه‌ی نهاییِ حل‌وفصل یه دور رأی‌گیری/دفاعیه.
class VoteResolution {
  final String message;
  final int? eliminatedPlayerId;

  const VoteResolution({required this.message, this.eliminatedPlayerId});
}

/// موتور اصلیِ گرداندن بازی: ترتیب صحبت روزها، چالش، رأی‌گیری و دفاعیه.
/// منطق فاز شب (به‌جز شب معارفه) عمداً خالیه؛ بعد از تعریف نقش‌ها تکمیل می‌شه.
class GameFlowController extends ChangeNotifier {
  final List<SessionPlayer> players;
  final GameSettings settings;

  GamePhaseType phase = GamePhaseType.introDay;
  int roundNumber = 0; // ۰ برای معارفه؛ ۱و۲و... برای روز/شب عادی

  /// ترتیب نوبت صحبت (شناسه‌ی بازیکن‌ها)، بر اساس بازیکن‌های زنده.
  List<int> _speakingOrder = [];
  int _speakerPointer = 0;

  VoteResolution? lastResolution;

  GameFlowController({required this.players, required this.settings}) {
    _rebuildSpeakingOrder();
  }

  List<SessionPlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList();

  int get aliveCount => players.where((p) => p.isAlive).length;

  SessionPlayer playerById(int id) => players.firstWhere((p) => p.id == id);

  void _rebuildSpeakingOrder() {
    _speakingOrder = players.where((p) => p.isAlive).map((p) => p.id).toList();
    _speakerPointer = 0;
    for (final p in players) {
      p.hasSpokenThisRound = false;
      p.challengeUsedToday = false;
    }
  }

  SessionPlayer? get currentSpeaker {
    if (_speakerPointer >= _speakingOrder.length) return null;
    return playerById(_speakingOrder[_speakerPointer]);
  }

  bool get isSpeakingRoundDone => _speakerPointer >= _speakingOrder.length;

  /// وقتی نوبتِ عادیِ بازیکن فعلی تموم شد (نه چالش)، برو سراغ نفر بعد.
  void advanceSpeaker() {
    final speaker = currentSpeaker;
    if (speaker != null) speaker.hasSpokenThisRound = true;
    _speakerPointer++;
    notifyListeners();
  }

  /// بازیکن‌های واجد شرایط برای گرفتن چالش امروز (زنده، چالشِ امروزشون
  /// استفاده نشده، و بازیکن فعلی نباشن).
  List<SessionPlayer> get challengeEligiblePlayers {
    final currentId = currentSpeaker?.id;
    return players
        .where((p) => p.isAlive && !p.challengeUsedToday && p.id != currentId)
        .toList();
  }

  /// شناسه‌ی بازیکنی که همین الان (به‌خاطر چالش) داره خارج از نوبت صحبت می‌کنه.
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

  /// یه بازیکن چالش می‌گیره و به‌جای صحبتِ الان، خودش صحبت می‌کنه؛
  /// بعدش نوبتِ بازیکنِ فعلی (که ازش چالش گرفته شده) دست‌نخورده می‌مونه.
  void useChallenge(int challengerId) {
    final challenger = playerById(challengerId);
    challenger.challengeUsedToday = true;
    _activeChallengerId = challengerId;
    notifyListeners();
  }

  /// وقتی صحبتِ چالش تموم شد، برمی‌گردیم به نوبتِ عادی (دست‌نخورده مونده).
  void finishChallenge() {
    _activeChallengerId = null;
    notifyListeners();
  }

  // ---------- انتقال بین فازها ----------

  void startIntroDay() {
    phase = GamePhaseType.introDay;
    roundNumber = 0;
    _rebuildSpeakingOrder();
    notifyListeners();
  }

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
    notifyListeners();
  }

  List<int> _defenseCandidateIds = [];
  int _defensePointer = 0;
  bool _isSecondRound = false;

  List<SessionPlayer> get defenseCandidates =>
      _defenseCandidateIds.map(playerById).toList();

  /// آیا الان توی بازه‌ی دفاعیه‌ایم؟ (از لحظه‌ی مشخص شدنِ نفرات دفاعیه تا
  /// شروعِ رأی‌گیریِ نهایی، شاملِ لحظه‌ای که همه‌ی نفرات صحبت کردن و
  /// منتظر دکمه‌ی «شروع رأی‌گیری نهایی»ایم.)
  bool get inDefense =>
      _defenseCandidateIds.isNotEmpty && !_isSecondRound && lastResolution == null;

  SessionPlayer? get currentDefenseSpeaker {
    if (_defensePointer >= _defenseCandidateIds.length) return null;
    return playerById(_defenseCandidateIds[_defensePointer]);
  }

  bool get isDefenseRoundDone => _defensePointer >= _defenseCandidateIds.length;

  void advanceDefenseSpeaker() {
    _defensePointer++;
    notifyListeners();
  }

  bool votingStarted = false;

  void startVoting() {
    votingStarted = true;
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

  /// بعد از رأی‌گیریِ اول: چه کسانی وارد دفاعیه می‌شن؟
  /// اگه کسی به آستانه نرسید، لیست خالی برمی‌گرده (یعنی امروز کسی حذف نمی‌شه).
  List<SessionPlayer> resolveFirstVoteRound() {
    final threshold = (aliveCount / 2).ceil();
    final candidates = players
        .where((p) => p.isAlive && p.votes >= threshold)
        .toList();
    _defenseCandidateIds = candidates.map((p) => p.id).toList();
    _defensePointer = 0;
    _isSecondRound = false;
    if (_defenseCandidateIds.isEmpty) {
      lastResolution = const VoteResolution(message: 'امروز کسی رأی کافی برای دفاعیه نیاورد.');
    }
    notifyListeners();
    return candidates;
  }

  /// شروع دور دوم رأی‌گیری (فقط بین نفرات دفاعیه‌رفته).
  void startSecondVoteRound() {
    _isSecondRound = true;
    for (final id in _defenseCandidateIds) {
      playerById(id).votes = 0;
    }
    notifyListeners();
  }

  bool get isSecondVoteRound => _isSecondRound;

  /// حل‌وفصل نهاییِ رأی‌گیریِ دوم طبق قوانین گفته‌شده.
  VoteResolution resolveSecondVoteRound() {
    final candidates = defenseCandidates;
    final threshold = (aliveCount / 2).ceil();

    if (candidates.length == 1) {
      final only = candidates.first;
      if (only.votes >= threshold) {
        only.isAlive = false;
        lastResolution = VoteResolution(
          message: '«${only.name}» با رأی کافی حذف شد.',
          eliminatedPlayerId: only.id,
        );
      } else {
        only.recordCount += 1;
        lastResolution = VoteResolution(
          message: '«${only.name}» رأی کافی نیاورد و سابقه‌دار شد.',
        );
      }
      return lastResolution!;
    }

    final maxVotes = candidates.map((p) => p.votes).reduce((a, b) => a > b ? a : b);
    final topByVotes = candidates.where((p) => p.votes == maxVotes).toList();

    if (topByVotes.length == 1) {
      final eliminated = topByVotes.first;
      eliminated.isAlive = false;
      for (final p in candidates) {
        if (p.id != eliminated.id) p.recordCount += 1;
      }
      lastResolution = VoteResolution(
        message: '«${eliminated.name}» با بیشترین رأی حذف شد.',
        eliminatedPlayerId: eliminated.id,
      );
      return lastResolution!;
    }

    // رأی‌ها برابره؛ سراغ سابقه می‌ریم
    final maxRecord = topByVotes.map((p) => p.recordCount).reduce((a, b) => a > b ? a : b);
    final topByRecord = topByVotes.where((p) => p.recordCount == maxRecord).toList();

    if (topByRecord.length == 1) {
      final eliminated = topByRecord.first;
      eliminated.isAlive = false;
      for (final p in candidates) {
        if (p.id != eliminated.id) p.recordCount += 1;
      }
      lastResolution = VoteResolution(
        message: '«${eliminated.name}» به‌خاطر سابقه‌ی بیشتر حذف شد.',
        eliminatedPlayerId: eliminated.id,
      );
      return lastResolution!;
    }

    // سابقه‌ها هم برابره؛ هیچ‌کس حذف نمی‌شه
    for (final p in candidates) {
      p.recordCount += 1;
    }
    lastResolution = const VoteResolution(
      message: 'رأی و سابقه‌ی نفرات دفاعیه برابر بود؛ امروز کسی حذف نشد.',
    );
    return lastResolution!;
  }

  void moveToNight(int nightNumber) {
    phase = GamePhaseType.night;
    roundNumber = nightNumber;
    notifyListeners();
  }
}
