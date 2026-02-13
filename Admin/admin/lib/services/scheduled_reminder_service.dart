import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class ScheduledReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy cấu hình nhắc nhở định kỳ
  Future<Map<String, dynamic>?> getScheduleConfig() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('daily_reminder')
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Lưu cấu hình nhắc nhở định kỳ
  Future<void> saveScheduleConfig({
    required bool enabled,
    required int hour,
    required int minute,
    required String title,
    required String message,
  }) async {
    await _firestore.collection('app_config').doc('daily_reminder').set({
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'title': title,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kiểm tra tất cả user và gửi nhắc nhở cho ai chưa có giao dịch hôm nay
  /// Trả về: { 'checked': tổng user, 'sent': số user được gửi, 'skipped': bỏ qua }
  Future<Map<String, int>> checkAndSendReminders({
    required String title,
    required String message,
    Function(int checked, int total)? onProgress,
  }) async {
    int checked = 0;
    int sent = 0;
    int skipped = 0;

    try {
      // 1. Lấy tất cả user active
      final usersSnap = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      final allUsers = usersSnap.docs.where((doc) {
        final data = doc.data();
        return data['role'] != 'admin';
      }).toList();

      final total = allUsers.length;

      // 2. Xác định khoảng thời gian "hôm nay" (00:00 - 23:59 UTC+7)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayStartTimestamp = Timestamp.fromDate(todayStart);
      final todayEndTimestamp = Timestamp.fromDate(todayEnd);

      // 3. Lấy tất cả expense hôm nay (1 query thay vì query từng user)
      final expensesSnap = await _firestore
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: todayStartTimestamp)
          .where('date', isLessThan: todayEndTimestamp)
          .get();

      // Tập hợp userId đã có giao dịch hôm nay
      final usersWithExpenses = <String>{};
      for (final doc in expensesSnap.docs) {
        final data = doc.data();
        if (data['userId'] != null) {
          usersWithExpenses.add(data['userId'] as String);
        }
      }

      // 4. Gửi notification cho user CHƯA có giao dịch
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final userDoc in allUsers) {
        checked++;
        final userId = userDoc.id;

        if (usersWithExpenses.contains(userId)) {
          // User đã có giao dịch hôm nay → bỏ qua
          skipped++;
        } else {
          // User chưa có giao dịch → gửi nhắc nhở
          final notification = NotificationModel(
            id: '',
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.reminder,
            isRead: false,
            createdAt: DateTime.now(),
          );

          final docRef = _firestore.collection('notifications').doc();
          batch.set(docRef, notification.toFirestore());
          batchCount++;
          sent++;

          // Commit batch mỗi 450 docs
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }

        onProgress?.call(checked, total);
      }

      // Commit batch cuối
      if (batchCount > 0) {
        await batch.commit();
      }

      // 5. Lưu log
      await _firestore.collection('admin_notification_logs').add({
        'adminId': 'system_scheduler',
        'title': title,
        'message': message,
        'type': 'reminder',
        'target': 'auto_reminder',
        'targetUserName': null,
        'sentCount': sent,
        'totalCount': total,
        'isContinuous': false,
        'repeatCount': 1,
        'intervalSeconds': 0,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'extra': {
          'skipped': skipped,
          'usersWithExpenses': usersWithExpenses.length,
        },
      });

      return {'checked': checked, 'sent': sent, 'skipped': skipped};
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách user chưa có giao dịch hôm nay (preview)
  Future<List<Map<String, dynamic>>> getUsersWithoutExpensesToday() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Lấy tất cả user active (không phải admin)
      final usersSnap = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      final allUsers = usersSnap.docs.where((doc) {
        final data = doc.data();
        return data['role'] != 'admin';
      }).toList();

      // Lấy expenses hôm nay
      final expensesSnap = await _firestore
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      final usersWithExpenses = <String>{};
      for (final doc in expensesSnap.docs) {
        final data = doc.data();
        if (data['userId'] != null) {
          usersWithExpenses.add(data['userId'] as String);
        }
      }

      // Trả về danh sách user chưa giao dịch
      return allUsers.where((doc) => !usersWithExpenses.contains(doc.id)).map((
        doc,
      ) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
