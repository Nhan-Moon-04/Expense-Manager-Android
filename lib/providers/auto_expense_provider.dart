import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../services/notification_listener_service.dart';
import '../services/expense_service.dart';

class AutoExpenseProvider with ChangeNotifier {
  final NotificationListenerService _notificationService =
      NotificationListenerService();
  final ExpenseService _expenseService = ExpenseService();

  bool _isEnabled = false;
  bool _isNotificationAccessGranted = false;
  bool _autoAddExpense = true;
  bool _autoAddIncome = true;
  bool _showConfirmation = true;

  final List<BankNotification> _pendingNotifications = [];
  final List<BankNotification> _processedNotifications = [];

  StreamSubscription? _subscription;
  String? _userId;

  bool get isEnabled => _isEnabled;
  bool get isNotificationAccessGranted => _isNotificationAccessGranted;
  bool get autoAddExpense => _autoAddExpense;
  bool get autoAddIncome => _autoAddIncome;
  bool get showConfirmation => _showConfirmation;
  List<BankNotification> get pendingNotifications => _pendingNotifications;
  List<BankNotification> get processedNotifications => _processedNotifications;

  AutoExpenseProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('auto_expense_enabled') ?? false;
    _autoAddExpense = prefs.getBool('auto_add_expense') ?? true;
    _autoAddIncome = prefs.getBool('auto_add_income') ?? true;
    _showConfirmation = prefs.getBool('auto_show_confirmation') ?? true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_expense_enabled', _isEnabled);
    await prefs.setBool('auto_add_expense', _autoAddExpense);
    await prefs.setBool('auto_add_income', _autoAddIncome);
    await prefs.setBool('auto_show_confirmation', _showConfirmation);
  }

  void setUserId(String userId) {
    _userId = userId;
    // Auto-start listening if enabled
    if (_isEnabled && _subscription == null) {
      _startListening();
    }
  }

  Future<void> checkNotificationAccess() async {
    _isNotificationAccessGranted = await _notificationService
        .isNotificationAccessEnabled();
    notifyListeners();
  }

  Future<void> requestNotificationAccess() async {
    await _notificationService.openNotificationAccessSettings();
  }

  Future<void> setEnabled(bool value) async {
    if (value && !_isNotificationAccessGranted) {
      await requestNotificationAccess();
      return;
    }

    _isEnabled = value;
    if (value) {
      _startListening();
    } else {
      _stopListening();
    }
    await _saveSettings();
    notifyListeners();
  }

  void setAutoAddExpense(bool value) {
    _autoAddExpense = value;
    _saveSettings();
    notifyListeners();
  }

  void setAutoAddIncome(bool value) {
    _autoAddIncome = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowConfirmation(bool value) {
    _showConfirmation = value;
    _saveSettings();
    notifyListeners();
  }

  void _startListening() {
    _notificationService.startListening();
    _subscription = _notificationService.notificationStream.listen(
      _handleNotification,
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _notificationService.stopListening();
  }

  void _handleNotification(BankNotification notification) {
    if (!_isEnabled || _userId == null) return;

    // Check if we should process this type
    if (notification.isExpense && !_autoAddExpense) return;
    if (notification.isIncome && !_autoAddIncome) return;

    if (_showConfirmation) {
      // Add to pending for user confirmation
      _pendingNotifications.insert(0, notification);
      notifyListeners();
    } else {
      // Auto-add directly
      _createExpenseFromNotification(notification);
    }
  }

  Future<void> confirmNotification(BankNotification notification) async {
    await _createExpenseFromNotification(notification);
    _pendingNotifications.remove(notification);
    _processedNotifications.insert(0, notification);
    notifyListeners();
  }

  void dismissNotification(BankNotification notification) {
    _pendingNotifications.remove(notification);
    notifyListeners();
  }

  Future<void> _createExpenseFromNotification(
    BankNotification notification,
  ) async {
    if (_userId == null) return;

    final expense = ExpenseModel(
      id: '',
      userId: _userId!,
      amount: notification.amount,
      category: _guessCategory(notification),
      type: notification.isExpense ? ExpenseType.expense : ExpenseType.income,
      date: notification.timestamp,
      description: '${notification.sourceName}: ${notification.description}',
      isAutoAdded: true,
    );

    try {
      await _expenseService.addExpense(expense);
    } catch (e) {
      debugPrint('Error auto-adding expense: $e');
    }
  }

  ExpenseCategory _guessCategory(BankNotification notification) {
    final text = '${notification.description} ${notification.rawText}'
        .toLowerCase();

    if (notification.isIncome) {
      if (text.contains('lương') || text.contains('salary')) {
        return ExpenseCategory.salary;
      }
      if (text.contains('thưởng') || text.contains('bonus')) {
        return ExpenseCategory.bonus;
      }
      return ExpenseCategory.other;
    }

    // Expense categories
    if (text.contains('ăn') ||
        text.contains('food') ||
        text.contains('nhà hàng') ||
        text.contains('quán') ||
        text.contains('grab food') ||
        text.contains('shopee food') ||
        text.contains('now') ||
        text.contains('baemin')) {
      return ExpenseCategory.food;
    }

    if (text.contains('grab') ||
        text.contains('taxi') ||
        text.contains('xe') ||
        text.contains('xăng') ||
        text.contains('gojek') ||
        text.contains('be')) {
      return ExpenseCategory.transport;
    }

    if (text.contains('shopee') ||
        text.contains('lazada') ||
        text.contains('tiki') ||
        text.contains('sendo') ||
        text.contains('mua') ||
        text.contains('shop')) {
      return ExpenseCategory.shopping;
    }

    if (text.contains('điện') ||
        text.contains('nước') ||
        text.contains('internet') ||
        text.contains('wifi') ||
        text.contains('thuê') ||
        text.contains('hóa đơn')) {
      return ExpenseCategory.bills;
    }

    if (text.contains('bệnh viện') ||
        text.contains('hospital') ||
        text.contains('thuốc') ||
        text.contains('khám') ||
        text.contains('phòng khám')) {
      return ExpenseCategory.health;
    }

    if (text.contains('học') ||
        text.contains('trường') ||
        text.contains('course') ||
        text.contains('khóa học')) {
      return ExpenseCategory.education;
    }

    if (text.contains('phim') ||
        text.contains('cinema') ||
        text.contains('game') ||
        text.contains('karaoke') ||
        text.contains('giải trí')) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.other;
  }

  @override
  void dispose() {
    _stopListening();
    _notificationService.dispose();
    super.dispose();
  }
}
