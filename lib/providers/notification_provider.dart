import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final PushNotificationService _pushService = PushNotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  /// Track notification IDs we already showed push for
  final Set<String> _shownPushIds = {};
  bool _isFirstLoad = true;

  StreamSubscription? _notifSubscription;
  StreamSubscription? _unreadSubscription;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to notifications
  void listenToNotifications(String userId) {
    _notifSubscription?.cancel();
    _unreadSubscription?.cancel();
    _isFirstLoad = true;

    _notifSubscription = _notificationService
        .getUserNotifications(userId)
        .listen((notifications) {
          if (_isFirstLoad) {
            // First load: mark all existing notification IDs as "already shown"
            // so we don't spam push notifications for old ones
            for (var n in notifications) {
              _shownPushIds.add(n.id);
            }
            _isFirstLoad = false;
          } else {
            // Subsequent updates: show push notification for NEW unread ones
            for (var n in notifications) {
              if (!n.isRead && !_shownPushIds.contains(n.id)) {
                _shownPushIds.add(n.id);
                _showPushForNotification(n);
              }
            }
          }

          _notifications = notifications;
          notifyListeners();
        });

    _unreadSubscription = _notificationService.getUnreadCount(userId).listen((
      count,
    ) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  /// Show a local push notification for an admin/system notification
  void _showPushForNotification(NotificationModel notification) {
    _pushService.showNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.message,
      payload: 'notification:${notification.id}',
    );
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      int index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }

      notifyListeners();
    } catch (e) {
      _setError('Không thể đánh dấu đã đọc.');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Không thể đánh dấu tất cả đã đọc.');
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Không thể xóa thông báo.');
      return false;
    }
  }

  // Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    _setLoading(true);
    try {
      await _notificationService.deleteAllNotifications(userId);
      _notifications.clear();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể xóa tất cả thông báo.');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear all local data (used when user deletes all data)
  void clearAllData() {
    _notifications.clear();
    _unreadCount = 0;
    _shownPushIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
