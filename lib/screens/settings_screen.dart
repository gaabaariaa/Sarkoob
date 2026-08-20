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
  String? _trackPath;
  String? _trackName;
  bool _busy = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await _storage.loadMusicPath();
    final name = await _storage.loadMusicName();
    if (!mounted) return;
    setState(() {
      _trackPath = path;
      _trackName = name;
    });
  }

  /// فایلِ انتخاب‌شده رو تو مسیرِ خودِ اپ کپی می‌کنه (نه فقط رفرنس به
  /// مسیرِ اصلی) تا نیازی به نگه‌داشتنِ دسترسیِ درازمدت به فایلِ سیستمِ
  /// کاربر نباشه، و بستنِ آهنگِ آماده تو اپ هم لازم نباشه (کپی‌رایته).
  Future<void> _pickMusic() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(type: FileType.audio);
      final picked = (result != null && result.files.isNotEmpty) ? result.files.single : null;
      final sourcePath = picked?.path;
      if (picked == null || sourcePath == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked.extension ?? 'mp3';
      final destPath = '${docsDir.path}/sarkoob_night_music.$ext';
      await File(sourcePath).copy(destPath);
      await _storage.saveMusicSelection(destPath, picked.name);
      MusicService.instance.setTrackPath(destPath);
      if (!mounted) return;
      setState(() {
        _trackPath = destPath;
        _trackName = picked.name;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا تو انتخابِ موزیک: $e')),
      );
    }
  }

  Future<void> _clearMusic() async {
    await MusicService.instance.stop();
    MusicService.instance.setTrackPath(null);
    await _storage.saveMusicSelection(null, null);
    if (!mounted) return;
    setState(() {
      _trackPath = null;
      _trackName = null;
      _previewing = false;
    });
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await MusicService.instance.stop();
    } else {
      MusicService.instance.setTrackPath(_trackPath);
      await MusicService.instance.play();
    }
    if (!mounted) return;
    setState(() => _previewing = !_previewing);
  }

  @override
  void dispose() {
    if (_previewing) {
      MusicService.instance.stop();
    }
    super.dispose();
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
            'یه آهنگ از گوشیت انتخاب کن تا خودکار تو فازِ شب و «خواب '
            'نیمروزی» پخش (و لوپ) بشه، و با شروعِ روز خودکار قطع بشه.',
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
                    _trackName ?? 'هیچ موزیکی انتخاب نشده',
                    style: TextStyle(
                      color: _trackName != null ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.library_music),
                        label: Text(_trackPath == null ? 'انتخابِ موزیک' : 'تعویضِ موزیک'),
                        onPressed: _busy ? null : _pickMusic,
                      ),
                      if (_trackPath != null) ...[
                        OutlinedButton.icon(
                          icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
                          label: Text(_previewing ? 'توقفِ پخشِ آزمایشی' : 'پخشِ آزمایشی'),
                          onPressed: _togglePreview,
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
