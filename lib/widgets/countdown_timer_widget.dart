import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// یه تایمر شمارش معکوس با دکمه‌ی شروع/توقف/ریست.
/// مهم: هروقت می‌خواید تایمر برای یه گوینده‌ی جدید از نو شروع بشه،
/// یه `key` متفاوت (مثلاً ValueKey(speakerId)) بهش بدید تا فلاتر
/// خودش state رو کامل از نو بسازه.
class CountdownTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onFinished;

  const CountdownTimerWidget({
    super.key,
    required this.totalSeconds,
    this.onFinished,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        widget.onFinished?.call();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = widget.totalSeconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    final isFinished = _remaining == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes:$seconds',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: isFinished ? AppColors.bloodRedLight : AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _running ? _pause : _start,
              child: Text(_running ? 'توقف' : 'شروع'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _reset, child: const Text('ریست')),
          ],
        ),
      ],
    );
  }
}
