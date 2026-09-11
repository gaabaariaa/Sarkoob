import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/history.dart';

/// نتیجه‌ی وارد‌کردنِ یه فایلِ بک‌آپ — چندتا آیتمِ *جدید* واقعاً اضافه/جایگزین شد.
class BackupImportResult {
  final int rosterCount;
  final int historyCount;
  const BackupImportResult({required this.rosterCount, required this.historyCount});
}

/// لایه‌ی سادهٔ ذخیره‌سازیِ محلی، رویِ SharedPreferences. لیستِ دائمیِ
/// بازیکن‌ها و تاریخچه‌ی بازی‌های تمام‌شده همینجا نگه‌داری می‌شن — هرچی
/// که تو خودِ گوشیِ گرداننده ذخیره می‌مونه، بینِ بازی‌ها پاک نمی‌شه.
class StorageService {
  static const _rosterKey = 'sarkoob_roster_v1';
  static const _historyKey = 'sarkoob_history_v1';
  static const _musicPathsKey = 'sarkoob_music_paths_v2';

  /// مسیرهای محلیِ فایل‌های موزیکِ انتخاب‌شده (کپیِ خودِ اپ، نه فایل/پوشه‌ی
  /// اصلیِ کاربر) — یه فایلِ تنها یا چندتا فایلِ یه پوشه، فرقی نداره،
  /// همیشه یه لیسته (خالی = چیزی انتخاب نشده).
  Future<List<String>> loadMusicPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_musicPathsKey) ?? [];
  }

  Future<void> saveMusicPaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_musicPathsKey, paths);
  }

  Future<List<SavedPlayerProfile>> loadRoster() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rosterKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return decodeRosterList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoster(List<SavedPlayerProfile> roster) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rosterKey, encodeRosterList(roster));
  }

  Future<List<GameHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return decodeHistoryList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<GameHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, encodeHistoryList(history));
  }

  /// یه رکوردِ جدید رو به تاریخچه اضافه می‌کنه (جدیدترین اولِ لیست).
  Future<void> addHistoryEntry(GameHistoryEntry entry) async {
    final current = await loadHistory();
    current.insert(0, entry);
    await saveHistory(current);
  }

  /// یه بازیکنِ جدید رو به لیستِ دائمی اضافه می‌کنه، مگراینکه از قبل
  /// (با همین اسمِ دقیق) توش باشه. آی‌دیِ جدید رو برمی‌گردونه (یا آی‌دیِ
  /// موجود اگه از قبل بوده).
  Future<String> ensurePlayerInRoster(String name) async {
    final roster = await loadRoster();
    final trimmed = name.trim();
    for (final p in roster) {
      if (p.name == trimmed) return p.id;
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    roster.add(SavedPlayerProfile(id: id, name: trimmed));
    await saveRoster(roster);
    return id;
  }

  /// یه رشته‌ی JSON شاملِ کلِ روستر و تاریخچه — برای بک‌آپ/انتقال بینِ گوشی‌ها.
  /// مسیرهای موزیک عمداً توش نیست (فایلِ محلیِ گوشیه، تو گوشیِ دیگه معنی نداره).
  Future<String> exportBackupJson() async {
    final roster = await loadRoster();
    final history = await loadHistory();
    final payload = {
      'type': 'sarkoob_backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'roster': roster.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// محتوایِ یه فایلِ بک‌آپ رو می‌خونه و روی داده‌ی فعلی اعمال می‌کنه.
  /// `merge=true`: فقط چیزهایِ جدید (بر اساسِ id/اسم) اضافه می‌شن، چیزی حذف نمی‌شه.
  /// `merge=false`: روستر و تاریخچه‌ی فعلی کاملاً با محتوایِ فایل جایگزین می‌شن.
  Future<BackupImportResult> importBackupJson(String raw, {required bool merge}) async {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('این فایل یه JSONِ معتبر نیست.');
    }
    if (decoded['roster'] == null && decoded['history'] == null) {
      throw const FormatException('این فایل شبیهِ بک‌آپِ سرکوب نیست.');
    }

    final importedRoster = ((decoded['roster'] as List?) ?? [])
        .map((e) => SavedPlayerProfile.fromJson(e as Map<String, dynamic>))
        .toList();
    final importedHistory = ((decoded['history'] as List?) ?? [])
        .map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    if (!merge) {
      await saveRoster(importedRoster);
      await saveHistory(importedHistory);
      return BackupImportResult(
        rosterCount: importedRoster.length,
        historyCount: importedHistory.length,
      );
    }

    // merge=true: یکتاسازیِ روستر بر اساسِ id یا اسمِ دقیق.
    final currentRoster = await loadRoster();
    final existingIds = currentRoster.map((e) => e.id).toSet();
    final existingNames = currentRoster.map((e) => e.name).toSet();
    var addedRoster = 0;
    for (final p in importedRoster) {
      if (existingIds.contains(p.id) || existingNames.contains(p.name)) continue;
      currentRoster.add(p);
      existingIds.add(p.id);
      existingNames.add(p.name);
      addedRoster++;
    }
    await saveRoster(currentRoster);

    // merge=true: یکتاسازیِ تاریخچه بر اساسِ id، بعد مرتب‌سازیِ جدیدترین‌اول.
    final currentHistory = await loadHistory();
    final existingHistoryIds = currentHistory.map((e) => e.id).toSet();
    var addedHistory = 0;
    for (final h in importedHistory) {
      if (existingHistoryIds.contains(h.id)) continue;
      currentHistory.add(h);
      existingHistoryIds.add(h.id);
      addedHistory++;
    }
    currentHistory.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    await saveHistory(currentHistory);

    return BackupImportResult(rosterCount: addedRoster, historyCount: addedHistory);
  }
}
