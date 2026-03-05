import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyCurrency = 'settings_currency';
  static const _keyLanguage = 'settings_language';
  static const _keyThemeMode = 'settings_theme_mode';

  String _currency = 'VND';
  String _language = 'vi';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  String get currency => _currency;
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  /// Currency format based on current setting
  NumberFormat get currencyFormat {
    switch (_currency) {
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$');
      case 'EUR':
        return NumberFormat.currency(locale: 'de_DE', symbol: '€');
      case 'VND':
      default:
        return NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    }
  }

  String get currencyDisplayName {
    switch (_currency) {
      case 'USD':
        return 'US Dollar (\$)';
      case 'EUR':
        return 'Euro (€)';
      case 'VND':
      default:
        return 'Việt Nam Đồng (₫)';
    }
  }

  String get languageDisplayName {
    switch (_language) {
      case 'en':
        return 'English';
      case 'vi':
      default:
        return 'Tiếng Việt';
    }
  }

  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.system:
        return 'Theo hệ thống';
    }
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_keyCurrency) ?? 'VND';
    _language = prefs.getString(_keyLanguage) ?? 'vi';
    AppLocalizations.setLanguage(_language);
    final themeStr = prefs.getString(_keyThemeMode) ?? 'light';
    _themeMode = _themeModeFromString(themeStr);
    _isLoaded = true;
    notifyListeners();
  }

  /// Load from user's Firestore settings map
  void loadFromUserSettings(Map<String, dynamic>? settings) {
    if (settings == null) return;
    if (settings.containsKey('currency')) {
      _currency = settings['currency'] as String;
    }
    if (settings.containsKey('language')) {
      _language = settings['language'] as String;
    }
    AppLocalizations.setLanguage(_language);
    if (settings.containsKey('themeMode')) {
      _themeMode = _themeModeFromString(settings['themeMode'] as String);
    }
    _isLoaded = true;
    _persistLocally();
    notifyListeners();
  }

  /// Set currency and persist
  Future<void> setCurrency(String currency) async {
    if (_currency == currency) return;
    _currency = currency;
    await _persistLocally();
    notifyListeners();
  }

  /// Set language and persist
  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    AppLocalizations.setLanguage(_language);
    await _persistLocally();
    notifyListeners();
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _persistLocally();
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  /// Get settings map for Firestore
  Map<String, dynamic> toSettingsMap() {
    return {
      'currency': _currency,
      'language': _language,
      'themeMode': _themeModeToString(_themeMode),
    };
  }

  Future<void> _persistLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, _currency);
    await prefs.setString(_keyLanguage, _language);
    await prefs.setString(_keyThemeMode, _themeModeToString(_themeMode));
  }
}
