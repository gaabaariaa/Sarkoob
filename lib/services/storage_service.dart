import 'package:shared_preferences/shared_preferences.dart';
import '../models/history.dart';

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
}
