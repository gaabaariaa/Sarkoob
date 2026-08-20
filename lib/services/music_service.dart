import 'package:audioplayers/audioplayers.dart';

/// سرویسِ پخشِ موزیکِ پس‌زمینه — یه singletonِ ساده و مستقل از هر
/// Widget خاصی، چون هم از صفحه‌ی تنظیمات (پخشِ آزمایشی، موقعِ انتخاب)
/// هم از صفحه‌ی گردانندگیِ زنده (پخشِ خودکار تو فازِ شب/خواب‌نیمروزی)
/// بهش نیاز داریم. فقط از فایلِ محلیِ کپی‌شده تو مسیرِ خودِ اپ پخش
/// می‌کنه (نه از فایلِ اصلیِ گوشیِ کاربر) — بخشِ ۱۳ فایلِ وضعیت رو ببین.
class MusicService {
  MusicService._internal();
  static final MusicService instance = MusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _trackPath;
  bool _isPlaying = false;

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
  String? get trackPath => _trackPath;

  /// فقط مسیر رو تو حافظه ست می‌کنه؛ چیزی پخش نمی‌کنه (اون کارِ play()ه).
  void setTrackPath(String? path) {
    _trackPath = path;
  }

  Future<void> play() async {
    final path = _trackPath;
    if (path == null) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(DeviceFileSource(path));
    _isPlaying = true;
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    await _player.stop();
    _isPlaying = false;
  }
}
