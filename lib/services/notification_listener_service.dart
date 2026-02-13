import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BankNotification {
  final String source;
  final String type; // 'expense' or 'income'
  final double amount;
  final String description;
  final String rawTitle;
  final String rawText;
  final String bankName;
  final String ruleName;
  final DateTime timestamp;

  BankNotification({
    required this.source,
    required this.type,
    required this.amount,
    required this.description,
    required this.rawTitle,
    required this.rawText,
    this.bankName = '',
    this.ruleName = '',
    required this.timestamp,
  });

  factory BankNotification.fromMap(Map<dynamic, dynamic> map) {
    return BankNotification(
      source: map['source'] as String? ?? 'unknown',
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      rawTitle: map['rawTitle'] as String? ?? '',
      rawText: map['rawText'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      ruleName: map['ruleName'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  String get sourceName {
    // Use bankName from remote JSON if available
    if (bankName.isNotEmpty) return bankName;
    switch (source) {
      case 'momo':
        return 'MoMo';
      case 'vcb':
        return 'Vietcombank';
      case 'mbbank':
        return 'MB Bank';
      case 'techcombank':
        return 'Techcombank';
      case 'bidv':
        return 'BIDV';
      case 'vietinbank':
        return 'VietinBank';
      case 'tpbank':
        return 'TPBank';
      case 'acb':
        return 'ACB';
      case 'sacombank':
        return 'Sacombank';
      case 'agribank':
        return 'Agribank';
      default:
        return 'Ngân hàng';
    }
  }
}

class NotificationListenerService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.expense_manager_android/notifications',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.expense_manager_android/notification_events',
  );

  static final NotificationListenerService _instance =
      NotificationListenerService._internal();
  factory NotificationListenerService() => _instance;
  NotificationListenerService._internal();

  StreamSubscription? _subscription;
  final _notificationController =
      StreamController<BankNotification>.broadcast();

  Stream<BankNotification> get notificationStream =>
      _notificationController.stream;

  /// Check if notification access is enabled
  Future<bool> isNotificationAccessEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isNotificationAccessEnabled',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking notification access: ${e.message}');
      return false;
    }
  }

  /// Open notification access settings
  Future<void> openNotificationAccessSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationAccessSettings');
    } on PlatformException catch (e) {
      debugPrint('Error opening notification settings: ${e.message}');
    }
  }

  /// Get list of supported banking apps
  Future<List<String>> getSupportedApps() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getSupportedApps',
      );
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      debugPrint('Error getting supported apps: ${e.message}');
      return [];
    }
  }

  /// Force refresh bank rules from remote JSON
  Future<bool> refreshBankRules() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'refreshBankRules',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error refreshing bank rules: ${e.message}');
      return false;
    }
  }

  /// Start listening for notifications
  void startListening() {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          try {
            final notification = BankNotification.fromMap(event);
            _notificationController.add(notification);
          } catch (e) {
            debugPrint('Error parsing notification: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );
  }

  /// Stop listening for notifications
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose the service
  void dispose() {
    stopListening();
    _notificationController.close();
  }
}
