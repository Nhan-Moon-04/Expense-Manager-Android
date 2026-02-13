import 'package:flutter/material.dart';
import '../services/scheduled_reminder_service.dart';

class ScheduledReminderProvider extends ChangeNotifier {
  final ScheduledReminderService _service = ScheduledReminderService();

  // Config state
  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;
  String _title = 'Nhắc nhở ghi chép chi tiêu';
  String _message =
      'Bạn chưa ghi chép chi tiêu hôm nay. Hãy cập nhật để quản lý tài chính tốt hơn nhé!';

  // Operation state
  bool _isLoading = false;
  bool _isSending = false;
  bool _isCheckingPreview = false;
  String? _errorMessage;
  String? _successMessage;
  int _sendProgress = 0;
  int _sendTotal = 0;

  // Result
  Map<String, int>? _lastResult;
  List<Map<String, dynamic>> _previewUsers = [];

  // Getters
  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;
  String get title => _title;
  String get message => _message;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isCheckingPreview => _isCheckingPreview;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get sendProgress => _sendProgress;
  int get sendTotal => _sendTotal;
  Map<String, int>? get lastResult => _lastResult;
  List<Map<String, dynamic>> get previewUsers => _previewUsers;

  String get timeDisplay =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  /// Tải cấu hình từ Firestore
  Future<void> loadConfig() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final config = await _service.getScheduleConfig();
      if (config != null) {
        _enabled = config['enabled'] ?? false;
        _hour = config['hour'] ?? 20;
        _minute = config['minute'] ?? 0;
        _title = config['title'] ?? _title;
        _message = config['message'] ?? _message;
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải cấu hình: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật cấu hình
  void updateEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  void updateTime(int hour, int minute) {
    _hour = hour;
    _minute = minute;
    notifyListeners();
  }

  void updateTitle(String value) {
    _title = value;
  }

  void updateMessage(String value) {
    _message = value;
  }

  /// Lưu cấu hình lên Firestore
  Future<void> saveConfig() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.saveScheduleConfig(
        enabled: _enabled,
        hour: _hour,
        minute: _minute,
        title: _title,
        message: _message,
      );
      _successMessage = 'Đã lưu cấu hình thành công!';
    } catch (e) {
      _errorMessage = 'Lỗi lưu cấu hình: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Preview danh sách user chưa giao dịch hôm nay
  Future<void> previewInactiveUsers() async {
    _isCheckingPreview = true;
    _errorMessage = null;
    _previewUsers = [];
    notifyListeners();

    try {
      _previewUsers = await _service.getUsersWithoutExpensesToday();
    } catch (e) {
      _errorMessage = 'Lỗi kiểm tra: $e';
    } finally {
      _isCheckingPreview = false;
      notifyListeners();
    }
  }

  /// Kiểm tra và gửi nhắc nhở ngay lập tức
  Future<void> sendRemindersNow() async {
    _isSending = true;
    _errorMessage = null;
    _successMessage = null;
    _lastResult = null;
    _sendProgress = 0;
    _sendTotal = 0;
    notifyListeners();

    try {
      final result = await _service.checkAndSendReminders(
        title: _title,
        message: _message,
        onProgress: (checked, total) {
          _sendProgress = checked;
          _sendTotal = total;
          notifyListeners();
        },
      );

      _lastResult = result;
      _successMessage =
          'Đã gửi nhắc nhở cho ${result['sent']} user '
          '(bỏ qua ${result['skipped']} user đã giao dịch)';
    } catch (e) {
      _errorMessage = 'Lỗi gửi nhắc nhở: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
