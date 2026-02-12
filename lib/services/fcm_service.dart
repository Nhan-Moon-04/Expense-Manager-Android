import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'push_notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Subscribe to topics for admin broadcasts
      await subscribeToTopic('all_users');
      await subscribeToTopic('promotions');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      _isInitialized = true;
      debugPrint('FCM Service initialized');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification when app is in foreground
      _pushNotificationService.showNotification(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        title: notification.title ?? 'Thông báo',
        body: notification.body ?? '',
        payload: jsonEncode(data),
      );

      // Save to Firestore notifications collection if needed
      _saveAdminNotification(
        title: notification.title ?? 'Thông báo',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  /// Handle when user taps on notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');

    final data = message.data;

    // Navigate to specific screen based on data
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      debugPrint('Should navigate to: $screen');
      // Navigation will be handled by the app
    }
  }

  /// Save admin notification to Firestore for history
  Future<void> _saveAdminNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'broadcast',
      });
    } catch (e) {
      debugPrint('Error saving admin notification: $e');
    }
  }

  /// Get list of admin broadcast notifications
  Stream<QuerySnapshot> getAdminNotifications() {
    return _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
