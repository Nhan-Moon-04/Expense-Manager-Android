import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../services/notification_listener_service.dart';
import 'expense_provider.dart';
import 'wallet_provider.dart';

class AutoExpenseProvider with ChangeNotifier, WidgetsBindingObserver {
  final NotificationListenerService _notificationService =
      NotificationListenerService();
  ExpenseProvider? _expenseProvider;
  WalletProvider? _walletProvider;

  bool _isEnabled = false;
  bool _isNotificationAccessGranted = false;
  bool _autoAddExpense = true;
  bool _autoAddIncome = true;
  bool _showConfirmation = false; // Always auto-add without confirmation
  bool _pendingEnable =
      false; // Track if user tried to enable but needs permission first
  Set<String> _disabledBanks = {}; // Banks that are disabled for auto-reading

  final List<BankNotification> _pendingNotifications = [];
  final List<BankNotification> _processedNotifications = [];

  StreamSubscription? _subscription;
  String? _userId;
  Timer? _pendingPollTimer;
  bool _isProcessingPending = false;

  bool get isEnabled => _isEnabled;
  bool get isNotificationAccessGranted => _isNotificationAccessGranted;
  bool get autoAddExpense => _autoAddExpense;
  bool get autoAddIncome => _autoAddIncome;
  bool get showConfirmation => _showConfirmation;
  List<BankNotification> get pendingNotifications => _pendingNotifications;
  List<BankNotification> get processedNotifications => _processedNotifications;
  Set<String> get disabledBanks => _disabledBanks;

  bool isBankEnabled(String bankSource) => !_disabledBanks.contains(bankSource);

  void setBankEnabled(String bankSource, bool enabled) {
    if (enabled) {
      _disabledBanks.remove(bankSource);
    } else {
      _disabledBanks.add(bankSource);
    }
    _saveSettings();
    notifyListeners();
  }

  AutoExpenseProvider() {
    _loadSettings();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('auto_expense_enabled') ?? false;
    _autoAddExpense = prefs.getBool('auto_add_expense') ?? true;
    _autoAddIncome = prefs.getBool('auto_add_income') ?? true;
    _showConfirmation = false; // Always auto-add without confirmation
    final disabledBanksList = prefs.getStringList('disabled_banks') ?? [];
    _disabledBanks = disabledBanksList.toSet();

    // Validate: if enabled but permission was revoked (e.g. after app update), disable
    if (_isEnabled) {
      _isNotificationAccessGranted = await _notificationService
          .isNotificationAccessEnabled();
      if (!_isNotificationAccessGranted) {
        debugPrint(
          '⚠️ Auto expense was enabled but permission is revoked - disabling',
        );
        _isEnabled = false;
        await prefs.setBool('auto_expense_enabled', false);
      }
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_expense_enabled', _isEnabled);
    await prefs.setBool('auto_add_expense', _autoAddExpense);
    await prefs.setBool('auto_add_income', _autoAddIncome);
    await prefs.setStringList('disabled_banks', _disabledBanks.toList());
    // No need to save _showConfirmation as it's always false
  }

  void setUserId(String userId) {
    _userId = userId;
    debugPrint('✅ User ID set: $userId');
    debugPrint('   - isEnabled: $_isEnabled');
    debugPrint(
      '   - ExpenseProvider: ${_expenseProvider != null ? "Ready" : "NULL"}',
    );

    // Always re-establish the stream listener (old subscription may be dead)
    if (_isEnabled) {
      debugPrint('   - Re-establishing notification listener...');
      _restartListening();
    }

    // Try to process pending notifications if ExpenseProvider is ready
    if (_expenseProvider != null) {
      _processPendingNotifications();
    } else {
      debugPrint(
        '⏳ Waiting for ExpenseProvider before processing pending notifications...',
      );
    }

    // Start periodic polling for pending notifications
    _startPendingPollTimer();
  }

  void setWalletProvider(WalletProvider provider) {
    _walletProvider = provider;
    debugPrint('✅ WalletProvider injected into AutoExpenseProvider');
  }

  void setExpenseProvider(ExpenseProvider provider) {
    _expenseProvider = provider;
    debugPrint('✅ ExpenseProvider injected into AutoExpenseProvider');

    // Process pending notifications if userId is ready
    if (_userId != null) {
      debugPrint(
        '🔄 Both userId and ExpenseProvider ready, processing pending notifications...',
      );
      _processPendingNotifications();
    }
  }

  /// Called when app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - re-checking notification access & listener');

      // Re-check notification access permission (may have changed while away)
      _recheckPermissionOnResume();

      // Re-establish EventChannel stream (may have died when Activity was destroyed)
      if (_isEnabled) {
        _restartListening();
      }
      // Process any pending notifications accumulated while app was in background
      if (_userId != null && _expenseProvider != null) {
        _processPendingNotifications();
      }
    }
  }

  /// Re-check permission when returning to app (e.g. after granting in system settings)
  Future<void> _recheckPermissionOnResume() async {
    final wasGranted = _isNotificationAccessGranted;
    _isNotificationAccessGranted = await _notificationService
        .isNotificationAccessEnabled();

    if (_isNotificationAccessGranted != wasGranted) {
      debugPrint(
        '🔑 Notification access changed: $wasGranted → $_isNotificationAccessGranted',
      );
    }

    // User just granted permission after trying to enable
    if (_pendingEnable && _isNotificationAccessGranted) {
      debugPrint('✅ Permission granted after pending enable - activating now');
      _pendingEnable = false;
      _isEnabled = true;
      _startListening();
      _startPendingPollTimer();
      await _saveSettings();
    }

    // Permission was revoked (e.g. after app update) but toggle still ON → disable
    if (_isEnabled && !_isNotificationAccessGranted) {
      debugPrint(
        '⚠️ Permission revoked but toggle was ON - disabling auto expense',
      );
      _isEnabled = false;
      _stopListening();
      await _saveSettings();
    }

    notifyListeners();
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
    debugPrint('🔄 Auto expense ${value ? "ENABLED" : "DISABLED"}');

    if (value) {
      // First check current permission status (fresh check)
      _isNotificationAccessGranted = await _notificationService
          .isNotificationAccessEnabled();

      if (!_isNotificationAccessGranted) {
        debugPrint(
          '⚠️ No notification access - opening settings, will auto-enable on return',
        );
        _pendingEnable = true;
        notifyListeners();
        await requestNotificationAccess();
        return;
      }
    }

    _pendingEnable = false;
    _isEnabled = value;
    debugPrint('   - userId: ${_userId != null ? "Set" : "NULL"}');
    debugPrint(
      '   - ExpenseProvider: ${_expenseProvider != null ? "Ready" : "NULL"}',
    );

    if (value) {
      _startListening();
      _startPendingPollTimer();
    } else {
      _stopListening();
      _pendingPollTimer?.cancel();
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

  void _startListening() async {
    debugPrint('🎧 Starting notification listener...');
    final started = await _notificationService.startForegroundService();

    if (!started) {
      debugPrint(
        '⚠️ Service instance null - calling ensureServiceRunning + retry',
      );
      await _notificationService.ensureServiceRunning();
      // Give Android time to rebind the NotificationListenerService
      await Future.delayed(const Duration(seconds: 3));
      final retryStarted = await _notificationService.startForegroundService();
      if (!retryStarted) {
        debugPrint('⚠️ Retry also failed - will rely on pending poll timer');
      }
    }

    _notificationService.startListening();
    _subscription = _notificationService.notificationStream.listen(
      _handleNotification,
    );
    debugPrint('✅ Notification listener started');
  }

  /// Cancel old subscription and re-create it (fixes dead EventChannel after Activity recreation)
  void _restartListening() async {
    debugPrint('🔄 Restarting notification listener...');
    _subscription?.cancel();
    _subscription = null;
    _notificationService.stopListening();
    // Ensure the native service is actually running before re-subscribing
    await _notificationService.ensureServiceRunning();
    _startListening();
  }

  /// Periodically poll pending queue to catch notifications missed by dead EventSink
  void _startPendingPollTimer() {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_userId != null && _expenseProvider != null && _isEnabled) {
        _processPendingNotifications();
      }
    });
    debugPrint('⏱️ Pending notification poll timer started (every 30s)');
  }

  void _stopListening() async {
    debugPrint('🔇 Stopping notification listener...');
    _subscription?.cancel();
    _subscription = null;
    _notificationService.stopListening();
    await _notificationService.stopForegroundService();
    debugPrint('✅ Notification listener stopped');
  }

  void _handleNotification(BankNotification notification) {
    debugPrint(
      '📱 Received bank notification: ${notification.sourceName} - ${notification.amount} (${notification.type})',
    );
    debugPrint('   Time: ${notification.timestamp}');
    debugPrint('   Description: ${notification.description}');

    if (!_isEnabled) {
      debugPrint('⚠️ Auto expense is disabled');
      return;
    }

    if (_userId == null) {
      debugPrint('⚠️ User ID is null');
      return;
    }

    if (_expenseProvider == null) {
      debugPrint('⚠️ ExpenseProvider is null');
      return;
    }

    // Check if we should process this type
    if (notification.isExpense && !_autoAddExpense) {
      debugPrint('⚠️ Auto-add expense is disabled');
      return;
    }
    if (notification.isIncome && !_autoAddIncome) {
      debugPrint('⚠️ Auto-add income is disabled');
      return;
    }

    // Check if specific bank is disabled
    if (_disabledBanks.contains(notification.source)) {
      debugPrint('⚠️ Bank ${notification.sourceName} is disabled');
      return;
    }

    debugPrint('✅ Processing notification...');
    if (_showConfirmation) {
      // Add to pending for user confirmation
      _pendingNotifications.insert(0, notification);
      notifyListeners();
    } else {
      // Auto-add directly (duplicate check is inside _createExpenseFromNotification)
      _createExpenseFromNotification(notification).then((_) {
        // Notify after expense is added to update UI
        notifyListeners();
      });
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
    if (_userId == null || _expenseProvider == null) {
      debugPrint(
        '❌ Cannot create expense: userId=${_userId != null ? "OK" : "NULL"}, expenseProvider=${_expenseProvider != null ? "OK" : "NULL"}',
      );
      return;
    }

    debugPrint('💰 Creating ${notification.type} from notification...');
    debugPrint('   Source: ${notification.sourceName}');
    debugPrint('   Amount: ${notification.amount}');
    debugPrint('   Date: ${notification.timestamp}');

    // Check for duplicates to avoid adding the same transaction multiple times
    final isDuplicate = await _checkDuplicate(notification);
    if (isDuplicate) {
      debugPrint('⚠️ Duplicate transaction detected, skipping...');
      debugPrint(
        '   Already exists: ${notification.sourceName} - ${notification.amount}đ',
      );
      return;
    }

    // Determine wallet based on bank source
    String? walletId;
    if (_walletProvider != null) {
      walletId = _walletProvider!.getWalletIdForBank(notification.source);
      walletId ??= _walletProvider!.primaryWallet?.id;
    }

    final expense = ExpenseModel(
      id: '',
      userId: _userId!,
      amount: notification.amount,
      category: _guessCategory(notification),
      type: notification.isExpense ? ExpenseType.expense : ExpenseType.income,
      date: notification.timestamp,
      description: '${notification.sourceName}: ${notification.description}',
      isAutoAdded: true,
      walletId: walletId,
      metadata: {
        'bankSource': notification.source,
        'bankName': notification.sourceName,
        'ruleName': notification.ruleName,
      },
    );

    try {
      // Use ExpenseProvider instead of ExpenseService directly
      // This ensures UI updates immediately
      debugPrint('   📤 Adding to ExpenseProvider...');
      final success = await _expenseProvider!.addExpense(expense);

      if (success) {
        debugPrint(
          '✅ Auto-added ${notification.isExpense ? "expense" : "income"}: ${notification.sourceName} - ${notification.amount}đ',
        );
        // Add to processed list to track successful additions
        _processedNotifications.insert(0, notification);
        if (_processedNotifications.length > 50) {
          _processedNotifications.removeRange(
            50,
            _processedNotifications.length,
          );
        }
      } else {
        debugPrint('❌ Failed to add expense: addExpense returned false');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error auto-adding expense: $e');
      debugPrint('   Stack trace: $stackTrace');
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

  /// Check if a similar transaction already exists to prevent duplicates
  /// Returns true if duplicate found, false otherwise
  Future<bool> _checkDuplicate(BankNotification notification) async {
    if (_userId == null || _expenseProvider == null) {
      return false;
    }

    try {
      // Check in recently processed notifications first (faster)
      for (final processed in _processedNotifications) {
        if (_isSameNotification(processed, notification)) {
          debugPrint('   🔍 Found duplicate in processed list');
          return true;
        }
      }

      // Check in database for recent transactions (within last 2 minutes)
      final now = notification.timestamp;
      final startTime = now.subtract(const Duration(minutes: 2));
      final endTime = now.add(const Duration(minutes: 2));

      final recentExpenses = await _expenseProvider!.getExpensesByDateRange(
        _userId!,
        startTime,
        endTime,
      );

      for (final expense in recentExpenses) {
        // Check if it's a very similar transaction
        if (expense.isAutoAdded &&
            expense.amount == notification.amount &&
            expense.type ==
                (notification.isExpense
                    ? ExpenseType.expense
                    : ExpenseType.income)) {
          // Check if timestamps are within 30 seconds
          final timeDiff = expense.date
              .difference(notification.timestamp)
              .abs();
          if (timeDiff.inSeconds < 30) {
            debugPrint('   🔍 Found duplicate in database');
            debugPrint(
              '      Existing: ${expense.description} at ${expense.date}',
            );
            debugPrint(
              '      New: ${notification.description} at ${notification.timestamp}',
            );
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking duplicate: $e');
      // If error checking duplicates, allow the transaction to prevent data loss
      return false;
    }
  }

  /// Check if two notifications are the same
  bool _isSameNotification(BankNotification n1, BankNotification n2) {
    // Same if amount, type match and timestamps are within 30 seconds
    if (n1.amount != n2.amount || n1.type != n2.type) {
      return false;
    }
    final timeDiff = n1.timestamp.difference(n2.timestamp).abs();
    return timeDiff.inSeconds < 30;
  }

  Future<void> _processPendingNotifications() async {
    // Prevent concurrent processing
    if (_isProcessingPending) {
      debugPrint('⏭️ Already processing pending notifications, skipping');
      return;
    }
    _isProcessingPending = true;

    if (_userId == null) {
      debugPrint('⚠️ Cannot process pending notifications: userId is NULL');
      return;
    }

    if (_expenseProvider == null) {
      debugPrint(
        '⚠️ Cannot process pending notifications: ExpenseProvider is NULL',
      );
      return;
    }

    debugPrint(
      '🔍 Checking for pending notifications from when app was killed...',
    );
    debugPrint('   ✅ userId: $_userId');
    debugPrint('   ✅ ExpenseProvider: Ready');

    try {
      final pendingNotifications = await _notificationService
          .getPendingNotifications();

      // Clear pending queue immediately so new notifications won't be mixed in
      await _notificationService.clearPendingNotifications();

      if (pendingNotifications.isEmpty) {
        debugPrint('✅ No pending notifications to process');
        return;
      }

      debugPrint(
        '📥 Processing ${pendingNotifications.length} pending notifications...',
      );

      int successCount = 0;
      int skipCount = 0;
      int duplicateCount = 0;

      for (final notification in pendingNotifications) {
        debugPrint(
          '   - Processing: ${notification.bankName} ${notification.amount} ${notification.type}',
        );

        // Check if we should process based on type
        if (notification.isExpense && !_autoAddExpense) {
          debugPrint('     ⏭️ Skipped (auto-add expense disabled)');
          skipCount++;
          continue;
        }
        if (notification.isIncome && !_autoAddIncome) {
          debugPrint('     ⏭️ Skipped (auto-add income disabled)');
          skipCount++;
          continue;
        }

        // Create expense from pending notification (duplicate check is inside)
        await _createExpenseFromNotification(notification);
        successCount++;
      }

      debugPrint('🎉 Processed all pending notifications:');
      debugPrint('   ✅ Successfully added: $successCount');
      debugPrint('   🔍 Duplicates skipped: $duplicateCount');
      debugPrint('   ⏭️ Other skipped: $skipCount');
    } catch (e) {
      debugPrint('❌ Error processing pending notifications: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    } finally {
      _isProcessingPending = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingPollTimer?.cancel();
    _stopListening();
    _notificationService.dispose();
    super.dispose();
  }
}
