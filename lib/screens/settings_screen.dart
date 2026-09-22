import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/music_service.dart';
import '../theme/app_language.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/game_3d_button.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  List<String> _trackPaths = [];
  bool _busy = false;
  bool _previewing = false;
  bool _backupBusy = false;

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
    if (_previewing) MusicService.instance.stop();
    super.dispose();
  }

  String _displayName(String path) {
    final base = path.split('/').last;
    final match = RegExp(r'^\d{3}_(.+)$').firstMatch(base);
    return match?.group(1) ?? base;
  }

  Future<List<String>> _copyToAppStorage(List<String> sourcePaths) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docsDir.path}/night_music');
    if (await musicDir.exists()) await musicDir.delete(recursive: true);
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
    setState(() { _trackPaths = saved; _busy = false; });
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFiles() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final paths = result.files.map((f) => f.path).whereType<String>().toList();
      if (paths.isEmpty) { _showError('فایل‌های انتخاب‌شده قابلِ‌خوندن نبودن.'); return; }
      await _applySelection(paths);
    } catch (e) { _showError('خطا تو انتخابِ موزیک: $e'); }
  }

  Future<void> _clearMusic() async {
    await MusicService.instance.stop();
    MusicService.instance.setPlaylist([]);
    await _storage.saveMusicPaths([]);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docsDir.path}/night_music');
      if (await musicDir.exists()) await musicDir.delete(recursive: true);
    } catch (_) {}
    if (!mounted) return;
    setState(() { _trackPaths = []; _previewing = false; });
  }

  Future<void> _togglePreview() async {
    if (_previewing) {
      await MusicService.instance.stop();
    } else {
      MusicService.instance.setPlaylist(_trackPaths);
      await MusicService.instance.play();
    }
    if (mounted) setState(() => _previewing = !_previewing);
  }

  void _showBackupError(String message) {
    if (!mounted) return;
    setState(() => _backupBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _timestampForFilename() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      final json = await _storage.exportBackupJson();
      final bytes = Uint8List.fromList(utf8.encode(json));
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'ذخیره‌ی فایلِ بک‌آپ',
        fileName: 'sarkoob_backup_${_timestampForFilename()}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() => _backupBusy = false);
      if (savedPath != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ بک‌آپ ذخیره شد.')));
    } catch (e) { _showBackupError('خطا تو گرفتنِ خروجی: $e'); }
  }

  Future<void> _importBackup() async {
    final mode = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.uiCard,
        title: Text('وارد کردنِ بک‌آپ'),
        content: Text('داده‌های فایل به داده‌های فعلی اضافه بشن یا کاملاً جایگزین بشن؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text('انصراف'.tr)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('افزودن به داده‌ی فعلی')),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('جایگزینیِ کامل', style: TextStyle(color: AppColors.bloodRedLight))),
        ],
      ),
    );
    if (mode == null || !mounted) return;
    if (mode == false) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.uiCard,
          title: Text('مطمئنی؟'),
          content: Text('روستر و تاریخچه‌ی فعلی پاک می‌شن و با فایل جایگزین می‌شن.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('انصراف'.tr)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('جایگزین کن', style: TextStyle(color: AppColors.bloodRedLight))),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    setState(() => _backupBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      final path = result?.files.single.path;
      if (path == null) { if (mounted) setState(() => _backupBusy = false); return; }
      final imported = await _storage.importBackupJson(await File(path).readAsString(), merge: mode);
      if (!mounted) return;
      setState(() => _backupBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mode ? '✅ ${imported.rosterCount} بازیکنِ جدید و ${imported.historyCount} بازیِ جدید اضافه شد.' : '✅ بازیابی شد: ${imported.rosterCount} بازیکن، ${imported.historyCount} بازی.')));
    } on FormatException catch (e) { _showBackupError(e.message); }
    catch (e) { _showBackupError('فایل خونده نشد یا خرابه: $e'); }
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) => Padding(padding: EdgeInsets.only(left: 2, right: 2), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(46), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.uiPrimaryLight, size: 20)), SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.headingFont(size: 19)), SizedBox(height: 2), Text(subtitle, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11))]))]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تنظیمات'.tr), actions: [Padding(padding: EdgeInsetsDirectional.only(end: 14), child: Center(child: Text('دست خدا'.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12))))],),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader(Icons.palette_rounded, 'ظاهر برنامه', 'شخصی‌سازی ظاهر میز بازی'),
          SizedBox(height: 14),
          _ThemePicker(),
          SizedBox(height: 28),
          _buildSectionHeader(Icons.language_rounded, 'تنظیمات زبان', 'زبان رابط کاربری برنامه را انتخاب کن'),
          SizedBox(height: 14),
          _LanguagePicker(),
          SizedBox(height: 28),
          _buildSectionHeader(Icons.music_note_rounded, 'موزیک شب', 'موسیقی خودکار فازهای شب و خواب نیمروزی'),
          SizedBox(height: 8),
          Text('چندتا فایلِ موزیک از گوشیت انتخاب کن تا خودکار تو فازِ شب و «خواب نیمروزی» به‌صورتِ شافل پخش بشن و با شروعِ روز قطع بشن.', style: TextStyle(color: Colors.white60, fontSize: 13)),
          SizedBox(height: 16),
          Container(decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.uiPrimary.withAlpha(41))), child: Padding(padding: EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_trackPaths.isEmpty ? 'هیچ موزیکی انتخاب نشده' : _trackPaths.length == 1 ? _displayName(_trackPaths.first) : '${_trackPaths.length} فایلِ موزیک انتخاب شده', style: TextStyle(color: _trackPaths.isNotEmpty ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
            if (_trackPaths.length > 1) ...[
              SizedBox(height: 8),
              ConstrainedBox(constraints: BoxConstraints(maxHeight: 140), child: ListView.builder(shrinkWrap: true, itemCount: _trackPaths.length, itemBuilder: (_, i) => Text('${i + 1}. ${_displayName(_trackPaths[i])}', style: TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis))),
            ],
            SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(icon: Icon(Icons.audio_file), label: Text('انتخابِ موزیک'), onPressed: _busy ? null : _pickFiles),
              if (_trackPaths.isNotEmpty) ...[
                OutlinedButton.icon(icon: Icon(_previewing ? Icons.stop : Icons.play_arrow), label: Text(_previewing ? 'توقفِ پخشِ آزمایشی' : 'پخشِ آزمایشی'), onPressed: _togglePreview),
                if (_previewing) OutlinedButton.icon(icon: Icon(Icons.skip_next), label: Text('بعدی'), onPressed: () => MusicService.instance.skipToNext()),
                OutlinedButton.icon(icon: Icon(Icons.delete_outline), label: Text('حذف'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.bloodRedLight), onPressed: _clearMusic),
              ],
            ]),
            if (_busy) ...[SizedBox(height: 12), LinearProgressIndicator()],
          ]))),
          SizedBox(height: 32),
          _buildSectionHeader(Icons.backup_rounded, 'بک‌آپ و بازیابی', 'انتقال و بازیابی اطلاعات بازی'),
          SizedBox(height: 8),
          Text('روستر و تاریخچه‌ی بازی‌ها را در یک فایل ذخیره کن تا بتوانی به گوشی دیگر منتقل یا از فایل قبلی بازیابی کنی.', style: TextStyle(color: Colors.white60, fontSize: 13)),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.uiPrimaryDark.withAlpha(46),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.cloud_sync_rounded, color: AppTheme.uiPrimaryLight),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'نسخه پشتیبان اطلاعات',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Game3DButton(
                        label: 'خروجی گرفتن',
                        icon: Icons.upload_rounded,
                        onPressed: _backupBusy ? null : _exportBackup,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Game3DButton(
                        label: 'بازیابی',
                        icon: Icons.download_rounded,
                        palette: Game3DPalette.dark,
                        onPressed: _backupBusy ? null : _importBackup,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_backupBusy) ...[
                  SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(minHeight: 5),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  _ThemePicker();



  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeId>(
      valueListenable: AppThemeController.current,
      builder: (context, selected, _) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...AppThemeId.values.map((id) => Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _ThemeOption(id: id, selected: selected == id, onTap: () => AppThemeController.set(id)),
          )),
        ]);
      },
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.current,
      builder: (context, selected, _) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.uiCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.uiPrimary.withAlpha(31)),
        ),
        child: Row(
          children: AppLanguage.values.map((language) => Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => AppLanguageController.set(language),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: selected == language ? AppTheme.uiPrimaryDark.withAlpha(89) : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: selected == language ? AppTheme.uiPrimary : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(language == AppLanguage.persian ? 'فارسی' : 'English', style: TextStyle(color: selected == language ? AppTheme.uiPrimaryLight : AppTheme.uiMutedText, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(language == AppLanguage.persian ? 'پیش‌فرض' : 'English', style: TextStyle(color: AppTheme.uiSubtleText, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeId id;
  final bool selected;
  final VoidCallback onTap;
  _ThemeOption({required this.id, required this.selected, required this.onTap});

  String get title => switch (id) { AppThemeId.darkGold => 'طلایی سلطنتی', AppThemeId.midnight => 'نیمه‌شب', AppThemeId.crimson => 'قرمز سینمایی' };
  String get subtitle => switch (id) { AppThemeId.darkGold => 'تم اصلی دست خدا', AppThemeId.midnight => 'سرد، تاریک و مدرن', AppThemeId.crimson => 'تیره با حال‌وهوای پرتنش' };
  Color get accent => switch (id) { AppThemeId.darkGold => AppColors.gold, AppThemeId.midnight => Color(0xFF9DB9D5), AppThemeId.crimson => Color(0xFFB84A4A) };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.uiCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent : AppTheme.uiPrimary.withAlpha(26), width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withAlpha(230), accent.withAlpha(89)]), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.palette_outlined, color: Colors.white.withAlpha(230))),
          SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), SizedBox(height: 3), Text(subtitle, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11))])),
          AnimatedSwitcher(duration: Duration(milliseconds: 180), child: selected ? Icon(Icons.check_circle_rounded, key: ValueKey('selected'), color: accent) : Icon(Icons.radio_button_unchecked, key: ValueKey('unselected'), color: AppTheme.uiSubtleText)),
        ]),
      ),
    );
  }
}
