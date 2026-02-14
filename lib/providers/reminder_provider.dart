import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/push_notification_service.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final NotificationService _notificationService = NotificationService();

  List<ReminderModel> _reminders = [];
  List<ReminderModel> _upcomingReminders = [];
  bool _isLoading = false;
  String? _error;

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get upcomingReminders => _upcomingReminders;
  List<ReminderModel> get activeReminders =>
      _reminders.where((r) => !r.isCompleted).toList();
  List<ReminderModel> get enabledReminders =>
      _reminders.where((r) => r.isActive && !r.isCompleted).toList();
  List<ReminderModel> get completedReminders =>
      _reminders.where((r) => r.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to reminders
  void listenToReminders(String userId) {
    _reminderService.getUserReminders(userId).listen((reminders) {
      _reminders = reminders;
      _scheduleAllReminders();
      _autoCompletePastReminders(userId);
      notifyListeners();
    });
  }

  // Auto-complete non-repeating reminders that have passed
  // For repeating reminders, advance reminderTime to the next occurrence
  Future<void> _autoCompletePastReminders(String userId) async {
    final now = DateTime.now();
    for (var reminder in _reminders) {
      if (!reminder.isCompleted &&
          reminder.isActive &&
          reminder.reminderTime.isBefore(now)) {
        if (reminder.repeat == ReminderRepeat.none) {
          // One-time reminder: mark as completed
          await _reminderService.markAsCompleted(reminder.id);
          await _cancelReminderNotification(reminder.id);
          await _createCompletionNotification(reminder);
        } else {
          // Repeating reminder: advance to next occurrence in Firestore
          final nextTime = _getNextOccurrence(
            reminder.reminderTime,
            reminder.repeat,
          );
          if (nextTime != null) {
            await _reminderService.updateReminder(
              reminder.copyWith(
                reminderTime: nextTime,
                updatedAt: DateTime.now(),
              ),
            );
          }
        }
      }
    }
  }

  // Calculate the next occurrence for a repeating reminder
  DateTime? _getNextOccurrence(DateTime current, ReminderRepeat repeat) {
    final now = DateTime.now();
    DateTime next = current;
    // Advance until we find a future time
    int safetyCounter = 0;
    while (next.isBefore(now) && safetyCounter < 1000) {
      switch (repeat) {
        case ReminderRepeat.daily:
          next = next.add(const Duration(days: 1));
          break;
        case ReminderRepeat.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case ReminderRepeat.monthly:
          next = DateTime(
            next.month == 12 ? next.year + 1 : next.year,
            next.month == 12 ? 1 : next.month + 1,
            next.day,
            next.hour,
            next.minute,
          );
          break;
        case ReminderRepeat.yearly:
          next = DateTime(
            next.year + 1,
            next.month,
            next.day,
            next.hour,
            next.minute,
          );
          break;
        case ReminderRepeat.none:
          return null;
      }
      safetyCounter++;
    }
    return next;
  }

  // Schedule push notifications for all active reminders
  void _scheduleAllReminders() {
    for (var reminder in enabledReminders) {
      _scheduleReminderNotification(reminder);
    }
  }

  // Schedule a single reminder notification
  // Uses repeating schedule for daily/weekly/monthly/yearly
  Future<void> _scheduleReminderNotification(ReminderModel reminder) async {
    try {
      final notificationId = reminder.id.hashCode;
      String body =
          reminder.description ?? 'Đến lúc thực hiện nhắc nhở của bạn';
      if (reminder.amount != null) {
        body = '${reminder.amount!.toStringAsFixed(0)}₫ - $body';
      }

      // Cancel existing first to avoid duplicates
      await _pushNotificationService.cancelNotification(notificationId);

      if (reminder.repeat == ReminderRepeat.none) {
        // One-time reminder: only schedule if in the future
        if (reminder.reminderTime.isAfter(DateTime.now())) {
          await _pushNotificationService.scheduleNotification(
            id: notificationId,
            title: '⏰ ${reminder.title}',
            body: body,
            scheduledDate: reminder.reminderTime,
            payload: 'reminder_${reminder.id}',
          );
        }
      } else {
        // Repeating reminder: use matchDateTimeComponents
        // This tells Android AlarmManager to repeat at the matching time pattern
        // Survives app kill AND device reboot (via ScheduledNotificationBootReceiver)
        final DateTimeComponents matchComponents;
        switch (reminder.repeat) {
          case ReminderRepeat.daily:
            matchComponents = DateTimeComponents.time;
            break;
          case ReminderRepeat.weekly:
            matchComponents = DateTimeComponents.dayOfWeekAndTime;
            break;
          case ReminderRepeat.monthly:
            matchComponents = DateTimeComponents.dayOfMonthAndTime;
            break;
          case ReminderRepeat.yearly:
            matchComponents = DateTimeComponents.dateAndTime;
            break;
          case ReminderRepeat.none:
            return; // Won't reach here
        }

        await _pushNotificationService.scheduleRepeatingNotification(
          id: notificationId,
          title: '⏰ ${reminder.title}',
          body: body,
          scheduledDate: reminder.reminderTime,
          matchComponents: matchComponents,
          payload: 'reminder_${reminder.id}',
        );
      }
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

  // Create in-app notification when reminder completes
  Future<void> _createCompletionNotification(ReminderModel reminder) async {
    try {
      String message = reminder.description ?? 'Nhắc nhở đã hoàn thành';
      if (reminder.amount != null) {
        message = '${reminder.amount!.toStringAsFixed(0)}₫ - $message';
      }
      await _notificationService.createReminderNotification(
        userId: reminder.userId,
        title: '✅ ${reminder.title}',
        message: message,
        data: {'reminderId': reminder.id},
      );
    } catch (e) {
      debugPrint('Error creating completion notification: $e');
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

      // Schedule push notification
      if (newReminder.isActive && !newReminder.isCompleted) {
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
      if (reminder.isActive && !reminder.isCompleted) {
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
        final reminder = _reminders[index];
        _reminders[index] = reminder.copyWith(isCompleted: true);

        // Create in-app notification
        await _createCompletionNotification(reminder);
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
        if (newActiveState && !_reminders[index].isCompleted) {
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

  /// Clear all local data (used when user deletes all data)
  void clearAllData() {
    _reminders.clear();
    _upcomingReminders.clear();
    notifyListeners();
  }
}
