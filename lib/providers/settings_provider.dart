import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyCurrency = 'settings_currency';
  static const _keyLanguage = 'settings_language';

  String _currency = 'VND';
  String _language = 'vi';
  bool _isLoaded = false;

  String get currency => _currency;
  String get language => _language;
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

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_keyCurrency) ?? 'VND';
    _language = prefs.getString(_keyLanguage) ?? 'vi';
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
    await _persistLocally();
    notifyListeners();
  }

  /// Get settings map for Firestore
  Map<String, dynamic> toSettingsMap() {
    return {'currency': _currency, 'language': _language};
  }

  Future<void> _persistLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, _currency);
    await prefs.setString(_keyLanguage, _language);
  }
}
