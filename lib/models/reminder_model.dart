import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderRepeat { none, daily, weekly, monthly, yearly }

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime reminderTime;
  final ReminderRepeat repeat;
  final bool isActive;
  final bool isCompleted;
  final double? amount;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.reminderTime,
    this.repeat = ReminderRepeat.none,
    this.isActive = true,
    this.isCompleted = false,
    this.amount,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      reminderTime:
          (data['reminderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repeat: ReminderRepeat.values.firstWhere(
        (e) => e.name == data['repeat'],
        orElse: () => ReminderRepeat.none,
      ),
      isActive: data['isActive'] ?? true,
      isCompleted: data['isCompleted'] ?? false,
      amount: data['amount']?.toDouble(),
      category: data['category'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'reminderTime': Timestamp.fromDate(reminderTime),
      'repeat': repeat.name,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'amount': amount,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? reminderTime,
    ReminderRepeat? repeat,
    bool? isActive,
    bool? isCompleted,
    double? amount,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      repeat: repeat ?? this.repeat,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String getRepeatName(ReminderRepeat repeat) {
    switch (repeat) {
      case ReminderRepeat.none:
        return 'Không lặp';
      case ReminderRepeat.daily:
        return 'Hàng ngày';
      case ReminderRepeat.weekly:
        return 'Hàng tuần';
      case ReminderRepeat.monthly:
        return 'Hàng tháng';
      case ReminderRepeat.yearly:
        return 'Hàng năm';
    }
  }
}
