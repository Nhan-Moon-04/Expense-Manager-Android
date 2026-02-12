import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final int memberCount;
  final double totalExpense;
  final double totalIncome;
  final DateTime createdAt;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.memberCount = 0,
    this.totalExpense = 0.0,
    this.totalIncome = 0.0,
    required this.createdAt,
    this.isActive = true,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> members = data['members'] ?? [];
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      ownerId: data['ownerId'] ?? '',
      memberCount: members.length,
      totalExpense: (data['totalExpense'] ?? 0.0).toDouble(),
      totalIncome: (data['totalIncome'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}
