import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderProvider with ChangeNotifier {
  final ReminderService _reminderService = ReminderService();

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
      notifyListeners();
    });
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
      _reminders.insert(0, newReminder);
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
