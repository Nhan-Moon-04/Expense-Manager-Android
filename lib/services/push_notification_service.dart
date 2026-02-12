import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone with Vietnam timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    _isInitialized = true;
    debugPrint(
      'PushNotificationService initialized with timezone: ${tz.local.name}',
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'expense_manager_channel',
          'Expense Manager',
          channelDescription: 'Thông báo từ ứng dụng quản lý chi tiêu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show reminder notification
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Nhắc nhở',
          channelDescription: 'Nhắc nhở chi tiêu và khoản thanh toán',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show expense notification (like bank transaction)
  Future<void> showExpenseNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'expense_channel',
          'Chi tiêu',
          channelDescription: 'Thông báo giao dịch và chi tiêu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.social,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show group notification
  Future<void> showGroupNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'group_channel',
          'Nhóm chi tiêu',
          channelDescription: 'Thông báo từ nhóm chi tiêu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Convert to TZDateTime
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // Don't schedule if the time has passed
    if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        'Notification not scheduled - time has passed: $scheduledDate',
      );
      return;
    }

    debugPrint(
      'Scheduling notification: id=$id, title=$title, time=$scheduledTZ',
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Nhắc nhở',
          channelDescription: 'Thông báo nhắc nhở chi tiêu',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('Notification scheduled successfully: id=$id');
  }

  /// Schedule a recurring daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_channel',
          'Nhắc nhở hàng ngày',
          channelDescription: 'Nhắc nhở hàng ngày về chi tiêu',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
