import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/push_notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  List<ReminderModel> _reminders = [];
  List<ReminderModel> _upcomingReminders = [];
  bool _isLoading = false;
  String? _error;

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get upcomingReminders => _upcomingReminders;
  List<ReminderModel> get activeReminders =>
      _reminders.where((r) => r.isActive && !r.isCompleted).toList();
  List<ReminderModel> get completedReminders =>
      _reminders.where((r) => r.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to reminders
  void listenToReminders(String userId) {
    _reminderService.getUserReminders(userId).listen((reminders) {
      _reminders = reminders;
      _scheduleAllReminders(); // Schedule push notifications for all active reminders
      notifyListeners();
    });
  }

  // Schedule push notifications for all active reminders
  void _scheduleAllReminders() {
    for (var reminder in activeReminders) {
      if (reminder.reminderTime.isAfter(DateTime.now())) {
        _scheduleReminderNotification(reminder);
      }
    }
  }

  // Schedule a single reminder notification
  Future<void> _scheduleReminderNotification(ReminderModel reminder) async {
    try {
      final notificationId = reminder.id.hashCode;
      String body =
          reminder.description ?? 'Đến lúc thực hiện nhắc nhở của bạn';
      if (reminder.amount != null) {
        body = '${reminder.amount!.toStringAsFixed(0)}₫ - $body';
      }

      await _pushNotificationService.scheduleNotification(
        id: notificationId,
        title: '⏰ ${reminder.title}',
        body: body,
        scheduledDate: reminder.reminderTime,
        payload: 'reminder_${reminder.id}',
      );
    } catch (e) {
      debugPrint('Error scheduling reminder notification: $e');
    }
  }

  // Cancel a reminder notification
  Future<void> _cancelReminderNotification(String reminderId) async {
    try {
      await _pushNotificationService.cancelNotification(reminderId.hashCode);
    } catch (e) {
      debugPrint('Error canceling reminder notification: $e');
    }
  }

  // Load upcoming reminders
  Future<void> loadUpcomingReminders(String userId) async {
    try {
      _upcomingReminders = await _reminderService.getUpcomingReminders(userId);
      notifyListeners();
    } catch (e) {
      _setError('Không thể tải nhắc nhở sắp tới.');
    }
  }

  // Add reminder
  Future<bool> addReminder(ReminderModel reminder) async {
    _setLoading(true);
    _clearError();

    try {
      ReminderModel newReminder = await _reminderService.addReminder(reminder);
      // Don't manually insert - Firestore stream will handle it

      // Schedule push notification if reminder is in the future
      if (newReminder.isActive &&
          newReminder.reminderTime.isAfter(DateTime.now())) {
        await _scheduleReminderNotification(newReminder);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể thêm nhắc nhở.');
      _setLoading(false);
      return false;
    }
  }

  // Update reminder
  Future<bool> updateReminder(ReminderModel reminder) async {
    _setLoading(true);
    _clearError();

    try {
      await _reminderService.updateReminder(reminder);

      int index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
      }

      // Update push notification
      await _cancelReminderNotification(reminder.id);
      if (reminder.isActive &&
          !reminder.isCompleted &&
          reminder.reminderTime.isAfter(DateTime.now())) {
        await _scheduleReminderNotification(reminder);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể cập nhật nhắc nhở.');
      _setLoading(false);
      return false;
    }
  }

  // Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    _setLoading(true);
    _clearError();

    try {
      await _reminderService.deleteReminder(reminderId);
      await _cancelReminderNotification(reminderId); // Cancel push notification
      _reminders.removeWhere((r) => r.id == reminderId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể xóa nhắc nhở.');
      _setLoading(false);
      return false;
    }
  }

  // Mark as completed
  Future<bool> markAsCompleted(String reminderId) async {
    try {
      await _reminderService.markAsCompleted(reminderId);
      await _cancelReminderNotification(reminderId); // Cancel push notification

      int index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        _reminders[index] = _reminders[index].copyWith(isCompleted: true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Không thể đánh dấu hoàn thành.');
      return false;
    }
  }

  // Toggle active
  Future<bool> toggleActive(String reminderId) async {
    try {
      int index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        bool newActiveState = !_reminders[index].isActive;
        await _reminderService.toggleActive(reminderId, newActiveState);
        _reminders[index] = _reminders[index].copyWith(
          isActive: newActiveState,
        );

        // Update push notification based on new state
        if (newActiveState &&
            _reminders[index].reminderTime.isAfter(DateTime.now())) {
          await _scheduleReminderNotification(_reminders[index]);
        } else {
          await _cancelReminderNotification(reminderId);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Không thể thay đổi trạng thái nhắc nhở.');
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

  void _clearError() {
    _error = null;
  }
}
