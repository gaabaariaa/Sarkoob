import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// سرویسِ پخشِ موزیکِ پس‌زمینه — یه singletonِ ساده و مستقل از هر
/// Widget خاصی، چون هم از صفحه‌ی تنظیمات (پخشِ آزمایشی، موقعِ انتخاب)
/// هم از صفحه‌ی گردانندگیِ زنده (پخشِ خودکار تو فازِ شب/خواب‌نیمروزی)
/// بهش نیاز داریم. فقط از فایلِ محلیِ کپی‌شده تو مسیرِ خودِ اپ پخش
/// می‌کنه (نه از فایلِ اصلیِ گوشیِ کاربر) — بخشِ ۱۳ فایلِ وضعیت رو ببین.
class MusicService {
  MusicService._internal() {
    // با تمومِ‌شدنِ هر فایل، خودکار برو سراغِ بعدی — اگه آخرین فایلِ
    // پلی‌لیست بود، برگرد به اول (یعنی «پخشِ لوپ‌شده» حالا در سطحِ
    // کلِ پلی‌لیسته، نه یه فایلِ تنها).
    _player.onPlayerComplete.listen((_) => _advanceAndPlay());
  }
  static final MusicService instance = MusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<String> _playlist = [];
  List<String> _playOrder = []; // چینشِ شافل‌شده‌ی همین دور
  int _orderPosition = 0;
  bool _isPlaying = false;

  final _random = Random();

  void _reshuffle() {
    _playOrder = List<String>.from(_playlist)..shuffle(_random);
    _orderPosition = 0;
  }

  // پلیرِ کاملاً جدا برای زنگِ پایانِ تایمر (صحبت/معارفه/چالش/دفاعیه) —
  // عمداً از پلیرِ موزیکِ شب جداست تا اگه (به‌ندرت) هم‌زمان لازم شدن،
  // روی هم سوار نشن. صدای خودِ زنگ باندل‌شده‌ی خودِ اپه (یه دینگ‌دانگِ
  // سنتزشده‌ی ساده، نه فایلِ کاربر)، نه چیزی که کاربر انتخاب کنه.
  final AudioPlayer _alertPlayer = AudioPlayer();
  bool _alertRinging = false;

  bool get isAlertRinging => _alertRinging;

  /// شروعِ زنگِ یکسره — تا صداش نکنی stopAlert، لوپ می‌مونه.
  Future<void> playAlertLoop() async {
    if (_alertRinging) return;
    _alertRinging = true;
    await _alertPlayer.setReleaseMode(ReleaseMode.loop);
    await _alertPlayer.play(AssetSource('sounds/timer_end.wav'));
  }

  Future<void> stopAlert() async {
    if (!_alertRinging) return;
    _alertRinging = false;
    await _alertPlayer.stop();
  }

  bool get isPlaying => _isPlaying;
  List<String> get playlist => _playlist;

  /// فقط لیست رو تو حافظه ست می‌کنه؛ چیزی پخش نمی‌کنه (اون کارِ play()ه).
  /// چه یه فایلِ تنها چه چندتا فایلِ یه پوشه، از دیدِ این سرویس فرقی
  /// ندارن — هردو یه «پلی‌لیست»ن، فقط طولشون فرق داره.
  void setPlaylist(List<String> paths) {
    _playlist = paths;
    _playOrder = [];
    _orderPosition = 0;
  }

  /// همیشه با یه چینشِ شافل‌شده‌ی تازه شروع می‌کنه — یعنی هر بار که موزیک
  /// از نو روشن بشه (هر شب/هر خواب‌نیمروزی)، ترتیبِ آهنگ‌ها فرق می‌کنه.
  Future<void> play() async {
    if (_playlist.isEmpty) return;
    _reshuffle();
    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.release);
    await _player.play(DeviceFileSource(_playOrder[_orderPosition]));
  }

  /// می‌ره سراغِ آهنگِ بعدیِ همین چینشِ شافل‌شده؛ وقتی چینش تموم شد،
  /// یه چینشِ شافل‌شده‌ی تازه می‌سازه (نه اینکه دوباره از همون ترتیب شروع
  /// کنه) تا تکرارها هم متنوع بمونن.
  Future<void> _advanceAndPlay() async {
    if (!_isPlaying || _playOrder.isEmpty) return;
    _orderPosition++;
    if (_orderPosition >= _playOrder.length) {
      _reshuffle();
    }
    await _player.play(DeviceFileSource(_playOrder[_orderPosition]));
  }

  /// دکمه‌ی «آهنگِ بعدی» — دستی، همون منطقِ رسیدن‌به‌آخرِ‌آهنگ رو صدا می‌زنه.
  Future<void> skipToNext() => _advanceAndPlay();

  Future<void> stop() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await _player.stop();
  }
}
