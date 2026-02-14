// core/services/language_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _currentLocale = const Locale('hi', 'IN');

  Locale get currentLocale => _currentLocale;

  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isHindi => _currentLocale.languageCode == 'hi';

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'hi';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLocale = isHindi
        ? const Locale('en', 'US')
        : const Locale('hi', 'IN');
    await setLanguage(newLocale);
  }

  String getLanguageName() {
    return isHindi ? 'हिंदी' : 'English';
  }

  String getLanguageCode() {
    return _currentLocale.languageCode;
  }
}
