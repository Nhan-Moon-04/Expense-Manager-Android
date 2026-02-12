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
  final String? groupId;
  final double amount;
  final ExpenseType type;
  final ExpenseCategory category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;
  final bool isAutoAdded;

  ExpenseModel({
    required this.id,
    required this.userId,
    this.groupId,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.receiptUrl,
    this.metadata,
    this.isAutoAdded = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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
      isAutoAdded: data['isAutoAdded'] ?? false,
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
      'isAutoAdded': isAutoAdded,
    };
  }
}
