import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  List<String> _trackPaths = [];
  bool _busy = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final paths = await _storage.loadMusicPaths();
    MusicService.instance.setPlaylist(paths);
    if (!mounted) return;
    setState(() => _trackPaths = paths);
  }

  @override
  void dispose() {
    if (_previewing) {
      MusicService.instance.stop();
    }
    super.dispose();
  }

  String _displayName(String path) {
    final base = path.split('/').last;
    final match = RegExp(r'^\d{3}_(.+)$').firstMatch(base);
    return match?.group(1) ?? base;
  }

  /// فایل‌های انتخاب‌شده (ممکنه یه فایل باشه یا چندتا) رو تو یه پوشه‌ی
  /// محلیِ خودِ اپ کپی می‌کنه (نه فقط رفرنس به مسیرِ اصلی) تا
  /// نیازی به نگه‌داشتنِ دسترسیِ درازمدت به فایل‌سیستمِ کاربر نباشه.
  /// هربار که موزیکِ جدید انتخاب می‌شه، محتوایِ قبلیِ این پوشه پاک می‌شه.
  Future<List<String>> _copyToAppStorage(List<String> sourcePaths) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docsDir.path}/night_music');
    if (await musicDir.exists()) {
      await musicDir.delete(recursive: true);
    }
    await musicDir.create(recursive: true);
    final result = <String>[];
    for (var i = 0; i < sourcePaths.length; i++) {
      final originalName = sourcePaths[i].split('/').last;
      final destPath = '${musicDir.path}/${i.toString().padLeft(3, '0')}_$originalName';
      await File(sourcePaths[i]).copy(destPath);
      result.add(destPath);
    }
    return result;
  }

  Future<void> _applySelection(List<String> sourcePaths) async {
    final saved = await _copyToAppStorage(sourcePaths);
    await _storage.saveMusicPaths(saved);
    MusicService.instance.setPlaylist(saved);
    if (!mounted) return;
    setState(() {
      _trackPaths = saved;
      _busy = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFiles() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final sourcePaths = result.files.map((f) => f.path).whereType<String>().toList();
      if (sourcePaths.isEmpty) {
        _showError('فایل‌های انتخاب‌شده قابلِ‌خوندن نبودن.');
        return;
      }
      await _applySelection(sourcePaths);
    } catch (e) {
      _showError('خطا تو انتخابِ موزیک: $e');
    }
  }

  Future<void> _clearMusic() async {
    await MusicService.instance.stop();
    MusicService.instance.setPlaylist([]);
    await _storage.saveMusicPaths([]);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/night_music');
      if (await musicDir.exists()) {
        await musicDir.delete(recursive: true);
      }
    } catch (_) {
      // پاک‌نشدنِ کپیِ محلی مهم نیست؛ چیزی که مهمه اینه که دیگه ازش
      // استفاده نمی‌شه (playlist و تنظیمات همین الان خالی شدن).
    }
    if (!mounted) return;
    setState(() {
      _trackPaths = [];
      _previewing = false;
    });
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await MusicService.instance.stop();
    } else {
      MusicService.instance.setPlaylist(_trackPaths);
      await MusicService.instance.play();
    }
    if (!mounted) return;
    setState(() => _previewing = !_previewing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('🎵 موزیکِ شب', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 8),
          const Text(
            'چندتا فایلِ موزیک از گوشیت انتخاب کن (می‌تونی همه‌ی آهنگ‌های یه '
            'پوشه رو با هم تیک بزنی) تا خودکار تو فازِ شب و «خواب نیمروزی» '
            'به‌صورتِ شافل پخش بشن، و با شروعِ روز خودکار قطع بشن.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.surfaceCard,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _trackPaths.isEmpty
                        ? 'هیچ موزیکی انتخاب نشده'
                        : _trackPaths.length == 1
                            ? _displayName(_trackPaths.first)
                            : '${_trackPaths.length} فایلِ موزیک انتخاب شده',
                    style: TextStyle(
                      color: _trackPaths.isNotEmpty ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_trackPaths.length > 1) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _trackPaths.length,
                        itemBuilder: (context, i) => Text(
                          '${i + 1}. ${_displayName(_trackPaths[i])}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.audio_file),
                        label: const Text('انتخابِ موزیک'),
                        onPressed: _busy ? null : _pickFiles,
                      ),
                      if (_trackPaths.isNotEmpty) ...[
                        OutlinedButton.icon(
                          icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
                          label: Text(_previewing ? 'توقفِ پخشِ آزمایشی' : 'پخشِ آزمایشی'),
                          onPressed: _togglePreview,
                        ),
                        if (_previewing)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.skip_next),
                            label: const Text('بعدی'),
                            onPressed: () => MusicService.instance.skipToNext(),
                          ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('حذف'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.bloodRedLight),
                          onPressed: _clearMusic,
                        ),
                      ],
                    ],
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('بقیه‌ی تنظیمات', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 8),
          const Text(
            'تنظیماتِ ویبره و تایمر به‌زودی همینجا میاد.',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
