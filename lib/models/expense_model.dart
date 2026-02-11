import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { income, expense }

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  salary,
  bonus,
  other,
}

class ExpenseModel {
  final String id;
  final String userId;
  final String? groupId; // null if personal expense
  final double amount;
  final ExpenseType type;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;

  ExpenseModel({
    required this.id,
    required this.userId,
    this.groupId,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.receiptUrl,
    this.metadata,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      groupId: data['groupId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: ExpenseType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ExpenseType.expense,
      ),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: data['description'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptUrl: data['receiptUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? groupId,
    double? amount,
    ExpenseType? type,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  static String getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn Uống';
      case ExpenseCategory.transport:
        return 'Di Chuyển';
      case ExpenseCategory.shopping:
        return 'Mua Sắm';
      case ExpenseCategory.entertainment:
        return 'Giải Trí';
      case ExpenseCategory.bills:
        return 'Hóa Đơn';
      case ExpenseCategory.health:
        return 'Sức Khỏe';
      case ExpenseCategory.education:
        return 'Giáo Dục';
      case ExpenseCategory.salary:
        return 'Lương';
      case ExpenseCategory.bonus:
        return 'Thưởng';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }
}
