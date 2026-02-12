import 'package:cloud_firestore/cloud_firestore.dart';

/// Model lưu lịch sử thông báo admin đã gửi
class AdminNotificationLog {
  final String id;
  final String adminId;
  final String title;
  final String message;
  final String type; // 'system', 'promotion'
  final String target; // 'all', 'user:<uid>'
  final String? targetUserName;
  final int sentCount;
  final int totalCount;
  final bool isContinuous;
  final int? intervalSeconds;
  final DateTime createdAt;
  final String status; // 'sending', 'completed', 'cancelled'

  AdminNotificationLog({
    required this.id,
    required this.adminId,
    required this.title,
    required this.message,
    required this.type,
    required this.target,
    this.targetUserName,
    this.sentCount = 0,
    this.totalCount = 1,
    this.isContinuous = false,
    this.intervalSeconds,
    required this.createdAt,
    this.status = 'completed',
  });

  factory AdminNotificationLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdminNotificationLog(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      target: data['target'] ?? 'all',
      targetUserName: data['targetUserName'],
      sentCount: data['sentCount'] ?? 0,
      totalCount: data['totalCount'] ?? 1,
      isContinuous: data['isContinuous'] ?? false,
      intervalSeconds: data['intervalSeconds'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'title': title,
      'message': message,
      'type': type,
      'target': target,
      'targetUserName': targetUserName,
      'sentCount': sentCount,
      'totalCount': totalCount,
      'isContinuous': isContinuous,
      'intervalSeconds': intervalSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
