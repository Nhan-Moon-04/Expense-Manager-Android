import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'groups';

  // Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Create group
  Future<GroupModel> createGroup({
    required String name,
    required String ownerId,
    String? description,
    String? avatarUrl,
    double? targetAmount,
    String? targetDescription,
    DateTime? targetDeadline,
    String? ownerDisplayName,
    String? ownerAvatarUrl,
  }) async {
    try {
      String inviteCode = _generateInviteCode();

      // Ensure invite code is unique
      while (await _isInviteCodeExists(inviteCode)) {
        inviteCode = _generateInviteCode();
      }

      GroupModel group = GroupModel(
        id: '',
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        ownerId: ownerId,
        inviteCode: inviteCode,
        members: [
          GroupMember(
            userId: ownerId,
            role: 'owner',
            contribution: 0.0,
            joinedAt: DateTime.now(),
            displayName: ownerDisplayName,
            avatarUrl: ownerAvatarUrl,
          ),
        ],
        totalExpense: 0.0,
        totalIncome: 0.0,
        targetAmount: targetAmount,
        targetDescription: targetDescription,
        targetDeadline: targetDeadline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(group.toFirestore());

      return group.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Check if invite code exists
  Future<bool> _isInviteCodeExists(String code) async {
    QuerySnapshot snapshot = await _firestore
        .collection(_collection)
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Join group by invite code
  Future<GroupModel?> joinGroup(
    String inviteCode,
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Mã nhóm không tồn tại');
      }

      DocumentSnapshot doc = snapshot.docs.first;
      GroupModel group = GroupModel.fromFirestore(doc);

      // Check if user is already a member
      if (group.memberIds.contains(userId)) {
        throw Exception('Bạn đã là thành viên của nhóm này');
      }

      // Add member
      GroupMember newMember = GroupMember(
        userId: userId,
        role: 'member',
        contribution: 0.0,
        joinedAt: DateTime.now(),
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      await _firestore.collection(_collection).doc(doc.id).update({
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'updatedAt': Timestamp.now(),
      });

      return group.copyWith(members: [...group.members, newMember]);
    } catch (e) {
      rethrow;
    }
  }

  // Leave group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(groupId)
          .get();
      GroupModel group = GroupModel.fromFirestore(doc);

      // Owner cannot leave, must transfer or delete
      if (group.ownerId == userId) {
        throw Exception(
          'Chủ nhóm không thể rời nhóm. Hãy chuyển quyền chủ nhóm trước.',
        );
      }

      // Remove member
      List<Map<String, dynamic>> updatedMembers = group.members
          .where((m) => m.userId != userId)
          .map((m) => m.toMap())
          .toList();

      await _firestore.collection(_collection).doc(groupId).update({
        'members': updatedMembers,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(group.id)
          .update(group.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user groups stream
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .where((group) => group.memberIds.contains(userId))
              .toList();
        });
  }

  // Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(groupId)
          .get();
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get group stream
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _firestore
        .collection(_collection)
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
  }

  // Update member contribution
  Future<void> updateMemberContribution(
    String groupId,
    String memberId,
    double amount, {
    bool isIncome = false,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(groupId)
          .get();
      GroupModel group = GroupModel.fromFirestore(doc);

      List<GroupMember> updatedMembers = group.members.map((m) {
        if (m.userId == memberId) {
          return GroupMember(
            userId: m.userId,
            role: m.role,
            contribution: m.contribution + amount,
            joinedAt: m.joinedAt,
            displayName: m.displayName,
            avatarUrl: m.avatarUrl,
          );
        }
        return m;
      }).toList();

      Map<String, dynamic> updateData = {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      };

      if (isIncome) {
        updateData['totalIncome'] = FieldValue.increment(amount);
      } else {
        updateData['totalExpense'] = FieldValue.increment(amount);
      }

      await _firestore.collection(_collection).doc(groupId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Calculate split for each member
  Map<String, double> calculateSplit(GroupModel group) {
    if (group.members.isEmpty) return {};

    double averageShare = group.totalExpense / group.members.length;
    Map<String, double> balances = {};

    for (var member in group.members) {
      // Positive means owes money, negative means owed money
      balances[member.userId] = averageShare - member.contribution;
    }

    return balances;
  }

  // Calculate user net debt: > 0 means user is owed, < 0 means user owes
  double getUserNetDebt(String userId, GroupModel group) {
    if (group.members.isEmpty) return 0.0;
    final member = group.members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => GroupMember(
        userId: userId,
        role: 'member',
        joinedAt: DateTime.now(),
      ),
    );
    final averageShare = group.totalExpense / group.members.length;
    return member.contribution - averageShare;
  }

  // Transaction minimization algorithm for debt settlement
  List<DebtModel> calculateDebts(GroupModel group) {
    if (group.members.length < 2 || group.totalExpense <= 0) return [];

    final double averageShare = group.totalExpense / group.members.length;
    final Map<String, GroupMember> memberMap = {
      for (var m in group.members) m.userId: m,
    };

    // Separate into debtors (owes > 0) and creditors (is owed > 0)
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    for (var m in group.members) {
      final double net = m.contribution - averageShare;
      if (net < -500.0) {
        debtors.add(MapEntry(m.userId, -net));
      } else if (net > 500.0) {
        creditors.add(MapEntry(m.userId, net));
      }
    }

    // Sort descending by magnitude to minimize transactions
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    List<DebtModel> debts = [];
    int d = 0;
    int c = 0;

    while (d < debtors.length && c < creditors.length) {
      final debtor = debtors[d];
      final creditor = creditors[c];

      final double settleAmount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      if (settleAmount >= 500.0) {
        final fromMember = memberMap[debtor.key];
        final toMember = memberMap[creditor.key];

        debts.add(
          DebtModel(
            fromUserId: debtor.key,
            fromUserName: fromMember?.displayName ?? 'Thành viên',
            fromAvatarUrl: fromMember?.avatarUrl,
            toUserId: creditor.key,
            toUserName: toMember?.displayName ?? 'Thành viên',
            toAvatarUrl: toMember?.avatarUrl,
            amount: settleAmount,
          ),
        );
      }

      debtors[d] = MapEntry(debtor.key, debtor.value - settleAmount);
      creditors[c] = MapEntry(creditor.key, creditor.value - settleAmount);

      if (debtors[d].value < 500.0) d++;
      if (creditors[c].value < 500.0) c++;
    }

    return debts;
  }
}
