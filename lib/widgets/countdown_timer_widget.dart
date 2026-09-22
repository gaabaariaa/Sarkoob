import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';

/// تایمر اصلیِ بازی. منطقِ شمارش معکوس دست‌نخورده است؛ این ویجت فقط
/// ظاهرِ میز بازی را مدرن‌تر می‌کند و از رنگ‌های هویتیِ ثابت استفاده می‌کند.
class CountdownTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onFinished;
  final VoidCallback? onSecondElapsed;

  CountdownTimerWidget({
    super.key,
    required this.totalSeconds,
    this.onFinished,
    this.onSecondElapsed,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _remaining;
  Timer? _timer;
  final AudioPlayer _soundPlayer = AudioPlayer();
  bool _running = false;
  bool _alarmStarted = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    // تایمرِ مرحله باید با ورود به مرحله خودش شروع شود؛
    // Play/Pause/Stop فقط کنترل دستیِ همین شمارش هستند.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_running && _remaining > 0) {
        _start();
      }
    });
  }

  Future<void> _playTimerBeep() async {
    try {
      await _soundPlayer.stop();
      await _soundPlayer.play(AssetSource('sounds/timer_end.wav'));
    } catch (_) {}
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_remaining == 10) _playTimerBeep();
      widget.onSecondElapsed?.call();
      if (_remaining <= 0) {
        if (!_alarmStarted) {
          _alarmStarted = true;
          widget.onFinished?.call();
        }
        _playTimerBeep();
        setState(() => _remaining--);
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _pause() {
    _timer?.cancel();
    _soundPlayer.stop();
    setState(() => _running = false);
  }

  void _stop() {
    _timer?.cancel();
    _soundPlayer.stop();
    setState(() {
      _running = false;
      _remaining = widget.totalSeconds;
      _alarmStarted = false;
    });
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalSeconds != widget.totalSeconds) {
      _timer?.cancel();
      _soundPlayer.stop();
      setState(() {
        _remaining = widget.totalSeconds;
        _running = false;
        _alarmStarted = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = _remaining < 0;
    final absoluteRemaining = _remaining.abs();
    final minutes = (absoluteRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (absoluteRemaining % 60).toString().padLeft(2, '0');
    final progress = widget.totalSeconds <= 0
        ? 0.0
        : (_remaining / widget.totalSeconds).clamp(0.0, 1.0);
    final urgent = _remaining <= 10;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (urgent ? AppColors.bloodRedLight : AppTheme.uiPrimary).withAlpha(184),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(82),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _running ? Icons.timer_outlined : Icons.pause_circle_outline,
                size: 17,
                color: urgent ? AppColors.bloodRedLight : AppTheme.uiPrimaryLight,
              ),
              SizedBox(width: 7),
              Text(
                _running ? 'زمانِ صحبت' : 'تایمر متوقف است',
                style: TextStyle(
                  color: AppTheme.uiMutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '${isNegative ? '-' : ''}$minutes:$seconds',
            style: TextStyle(
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: urgent ? AppColors.bloodRedLight : AppTheme.uiPrimaryLight,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: AppTheme.uiBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                urgent ? AppColors.bloodRedLight : AppTheme.uiPrimary,
              ),
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _running ? _pause : _start,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow, size: 18),
                  label: Text(_running ? 'مکث' : 'پخش'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _stop,
                  icon: Icon(Icons.stop, size: 18),
                  label: Text('توقف'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
