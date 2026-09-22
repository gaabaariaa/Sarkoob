import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { persian, english }

class AppLanguageController {
  static const _key = 'app_language';
  static final ValueNotifier<AppLanguage> current = ValueNotifier(AppLanguage.persian);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    current.value = AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.persian,
    );
  }

  static Future<void> set(AppLanguage language) async {
    current.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.name);
  }

  static Locale get locale => current.value == AppLanguage.english
      ? const Locale('en')
      : const Locale('fa');
}
