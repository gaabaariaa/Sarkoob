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
