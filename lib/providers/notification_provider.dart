import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to notifications
  void listenToNotifications(String userId) {
    _notificationService.getUserNotifications(userId).listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });

    _notificationService.getUnreadCount(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
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
}
