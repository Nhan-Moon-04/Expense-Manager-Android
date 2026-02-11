import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Add notification
  Future<NotificationModel> addNotification(
    NotificationModel notification,
  ) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(notification.toFirestore());
      return notification.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Create system notification
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await addNotification(notification);
    } catch (e) {
      rethrow;
    }
  }

  // Create reminder notification
  Future<void> createReminderNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: NotificationType.reminder,
        isRead: false,
        data: data,
        createdAt: DateTime.now(),
      );
      await addNotification(notification);
    } catch (e) {
      rethrow;
    }
  }

  // Create group notification
  Future<void> createGroupNotification({
    required String userId,
    required String title,
    required String message,
    required String groupId,
    NotificationType type = NotificationType.groupExpense,
  }) async {
    try {
      NotificationModel notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        data: {'groupId': groupId},
        createdAt: DateTime.now(),
      );
      await addNotification(notification);
    } catch (e) {
      rethrow;
    }
  }
}
