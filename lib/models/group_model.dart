import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String userId;
  final String role; // 'owner', 'admin', 'member'
  final double contribution;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.role,
    this.contribution = 0.0,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> data) {
    return GroupMember(
      userId: data['userId'] ?? '',
      role: data['role'] ?? 'member',
      contribution: (data['contribution'] ?? 0.0).toDouble(),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'contribution': contribution,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final String inviteCode;
  final List<GroupMember> members;
  final double totalExpense;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.inviteCode,
    required this.members,
    this.totalExpense = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<GroupMember> membersList = [];
    if (data['members'] != null) {
      membersList = (data['members'] as List)
          .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
          .toList();
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      avatarUrl: data['avatarUrl'],
      ownerId: data['ownerId'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      members: membersList,
      totalExpense: (data['totalExpense'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'members': members.map((m) => m.toMap()).toList(),
      'totalExpense': totalExpense,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? ownerId,
    String? inviteCode,
    List<GroupMember>? members,
    double? totalExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      totalExpense: totalExpense ?? this.totalExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  List<String> get memberIds => members.map((m) => m.userId).toList();
}
