import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  final List<Locale> supportedLocales = const [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
  ];

  final Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
  };

  LocalizationService();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      _currentLocale = Locale(languageCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
    }
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  bool isRTL() {
    return _currentLocale.languageCode == 'ar';
  }
}
