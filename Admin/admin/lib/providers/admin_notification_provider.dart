import 'dart:async';
import 'package:flutter/material.dart';
import '../models/admin_notification_log.dart';
import '../models/notification_model.dart';
import '../services/admin_notification_service.dart';

class AdminNotificationProvider extends ChangeNotifier {
  final AdminNotificationService _notifService = AdminNotificationService();

  List<AdminNotificationLog> _logs = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _sendProgress = 0;
  int _sendTotal = 0;
  bool _shouldCancel = false;

  StreamSubscription? _logsSubscription;

  List<AdminNotificationLog> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  int get sendProgress => _sendProgress;
  int get sendTotal => _sendTotal;

  /// Lắng nghe lịch sử thông báo
  void listenToLogs() {
    _isLoading = true;
    notifyListeners();

    _logsSubscription?.cancel();
    _logsSubscription = _notifService.getNotificationLogs().listen(
      (logs) {
        _logs = logs;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Gửi thông báo cho 1 user
  Future<bool> sendToUser({
    required String adminId,
    required String userId,
    required String userName,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notifService.sendToUser(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );

      // Lưu log
      await _notifService.saveNotificationLog(
        AdminNotificationLog(
          id: '',
          adminId: adminId,
          title: title,
          message: message,
          type: type.name,
          target: 'user:$userId',
          targetUserName: userName,
          sentCount: 1,
          totalCount: 1,
          createdAt: DateTime.now(),
          status: 'completed',
        ),
      );

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Gửi thông báo cho tất cả
  Future<bool> sendToAll({
    required String adminId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      int sent = await _notifService.sendToAllUsers(
        title: title,
        message: message,
        type: type,
        onProgress: (s, t) {
          _sendProgress = s;
          _sendTotal = t;
          notifyListeners();
        },
      );

      // Lưu log
      await _notifService.saveNotificationLog(
        AdminNotificationLog(
          id: '',
          adminId: adminId,
          title: title,
          message: message,
          type: type.name,
          target: 'all',
          sentCount: sent,
          totalCount: sent,
          createdAt: DateTime.now(),
          status: 'completed',
        ),
      );

      _isSending = false;
      _sendProgress = 0;
      _sendTotal = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Gửi thông báo liên tục
  Future<bool> sendContinuously({
    required String adminId,
    String? userId,
    String? userName,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    required int repeatCount,
    required int intervalSeconds,
  }) async {
    _isSending = true;
    _shouldCancel = false;
    _sendProgress = 0;
    _sendTotal = repeatCount;
    _errorMessage = null;
    notifyListeners();

    // Tạo log trước
    String logId = await _notifService.saveNotificationLog(
      AdminNotificationLog(
        id: '',
        adminId: adminId,
        title: title,
        message: message,
        type: type.name,
        target: userId != null ? 'user:$userId' : 'all',
        targetUserName: userName,
        sentCount: 0,
        totalCount: repeatCount,
        isContinuous: true,
        intervalSeconds: intervalSeconds,
        createdAt: DateTime.now(),
        status: 'sending',
      ),
    );

    try {
      await _notifService.sendContinuously(
        userId: userId,
        title: title,
        message: message,
        type: type,
        repeatCount: repeatCount,
        intervalSeconds: intervalSeconds,
        onProgress: (sent, total) {
          _sendProgress = sent;
          _sendTotal = total;
          notifyListeners();

          // Cập nhật log
          _notifService.updateNotificationLog(logId, {
            'sentCount': sent,
            'status': sent >= total ? 'completed' : 'sending',
          });
        },
        shouldContinue: () => !_shouldCancel,
      );

      // Cập nhật status cuối
      await _notifService.updateNotificationLog(logId, {
        'status': _shouldCancel ? 'cancelled' : 'completed',
        'sentCount': _sendProgress,
      });

      _isSending = false;
      _sendProgress = 0;
      _sendTotal = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      await _notifService.updateNotificationLog(logId, {
        'status': 'cancelled',
        'sentCount': _sendProgress,
      });
      notifyListeners();
      return false;
    }
  }

  /// Hủy gửi liên tục
  void cancelSending() {
    _shouldCancel = true;
    notifyListeners();
  }

  /// Xóa log
  Future<void> deleteLog(String logId) async {
    try {
      await _notifService.deleteNotificationLog(logId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}
