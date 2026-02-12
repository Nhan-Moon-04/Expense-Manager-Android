import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/admin_notification_log.dart';

class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gửi thông báo cho 1 user
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
  }) async {
    try {
      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Gửi thông báo cho tất cả users
  Future<int> sendToAllUsers({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      // Lấy tất cả users active
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      int total = usersSnapshot.docs.length;
      int sent = 0;

      // Gửi từng batch 500
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        NotificationModel notification = NotificationModel(
          id: '',
          userId: userDoc.id,
          title: title,
          message: message,
          type: type,
          isRead: false,
          createdAt: DateTime.now(),
        );

        DocumentReference docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toFirestore());
        batchCount++;
        sent++;

        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          onProgress?.call(sent, total);
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        onProgress?.call(sent, total);
      }

      return sent;
    } catch (e) {
      rethrow;
    }
  }

  /// Gửi thông báo liên tục (nhiều lần)
  Future<void> sendContinuously({
    required String? userId, // null = gửi all
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    required int repeatCount,
    required int intervalSeconds,
    required Function(int sent, int total) onProgress,
    required bool Function() shouldContinue,
  }) async {
    for (int i = 0; i < repeatCount; i++) {
      if (!shouldContinue()) break;

      if (userId != null) {
        await sendToUser(
          userId: userId,
          title: title,
          message: message,
          type: type,
        );
      } else {
        await sendToAllUsers(title: title, message: message, type: type);
      }

      onProgress(i + 1, repeatCount);

      if (i < repeatCount - 1 && shouldContinue()) {
        await Future.delayed(Duration(seconds: intervalSeconds));
      }
    }
  }

  /// Lưu log thông báo admin đã gửi
  Future<String> saveNotificationLog(AdminNotificationLog log) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('admin_notification_logs')
          .add(log.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật log
  Future<void> updateNotificationLog(
    String logId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('admin_notification_logs')
          .doc(logId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy lịch sử thông báo admin đã gửi
  Stream<List<AdminNotificationLog>> getNotificationLogs() {
    return _firestore
        .collection('admin_notification_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminNotificationLog.fromFirestore(doc))
              .toList(),
        );
  }

  /// Xóa admin notification log
  Future<void> deleteNotificationLog(String logId) async {
    try {
      await _firestore
          .collection('admin_notification_logs')
          .doc(logId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
