import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../services/group_service.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  final ExpenseService _expenseService = ExpenseService();
  final AuthService _authService = AuthService();

  List<GroupModel> _groups = [];
  GroupModel? _selectedGroup;
  List<ExpenseModel> _groupExpenses = [];
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  GroupModel? get selectedGroup => _selectedGroup;
  List<ExpenseModel> get groupExpenses => _groupExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to groups
  void listenToGroups(String userId) {
    _groupService.getUserGroups(userId).listen((groups) {
      _groups = groups;
      notifyListeners();
    });
  }

  // Listen to group expenses
  void listenToGroupExpenses(String groupId) {
    _expenseService.getGroupExpenses(groupId).listen((expenses) {
      _groupExpenses = expenses;
      notifyListeners();
    });
  }

  // Create group
  Future<bool> createGroup({
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
    _setLoading(true);
    _clearError();

    try {
      await _groupService.createGroup(
        name: name,
        ownerId: ownerId,
        description: description,
        avatarUrl: avatarUrl,
        targetAmount: targetAmount,
        targetDescription: targetDescription,
        targetDeadline: targetDeadline,
        ownerDisplayName: ownerDisplayName,
        ownerAvatarUrl: ownerAvatarUrl,
      );
      // Stream listener (listenToGroups) will update the list automatically
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể tạo nhóm.');
      _setLoading(false);
      return false;
    }
  }

  // Join group
  Future<bool> joinGroup(
    String inviteCode,
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.joinGroup(
        inviteCode,
        userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      // Stream listener (listenToGroups) will update the list automatically
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Leave group
  Future<bool> leaveGroup(String groupId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.leaveGroup(groupId, userId);
      _groups.removeWhere((g) => g.id == groupId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Update group
  Future<bool> updateGroup(GroupModel group) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.updateGroup(group);

      int index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể cập nhật nhóm.');
      _setLoading(false);
      return false;
    }
  }

  // Delete group
  Future<bool> deleteGroup(String groupId) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.deleteGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể xóa nhóm.');
      _setLoading(false);
      return false;
    }
  }

  // Add group expense
  Future<bool> addGroupExpense(ExpenseModel expense) async {
    _setLoading(true);
    _clearError();

    try {
      ExpenseModel newExpense = await _expenseService.addExpense(expense);
      _groupExpenses.insert(0, newExpense);

      // Update member contribution
      if (expense.groupId != null) {
        await _groupService.updateMemberContribution(
          expense.groupId!,
          expense.userId,
          expense.amount,
          isIncome: expense.type == ExpenseType.income,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể thêm chi tiêu nhóm.');
      _setLoading(false);
      return false;
    }
  }

  // Select group
  void selectGroup(GroupModel group) {
    _selectedGroup = group;
    listenToGroupExpenses(group.id);
    notifyListeners();
    // Fetch display names for members that don't have one
    _enrichMemberData(group);
  }

  // Fetch user info for members missing displayName
  Future<void> _enrichMemberData(GroupModel group) async {
    bool updated = false;
    List<GroupMember> enrichedMembers = List.from(group.members);

    for (int i = 0; i < enrichedMembers.length; i++) {
      final member = enrichedMembers[i];
      if (member.displayName == null || member.displayName!.isEmpty) {
        try {
          final userData = await _authService.getUserData(member.userId);
          if (userData != null) {
            enrichedMembers[i] = member.copyWith(
              displayName: userData.fullName,
              avatarUrl: userData.avatarUrl,
            );
            updated = true;
          }
        } catch (e) {
          debugPrint('Error fetching user data for ${member.userId}: $e');
        }
      }
    }

    if (updated) {
      _selectedGroup = group.copyWith(members: enrichedMembers);
      notifyListeners();
      // Also update in Firestore so next time it's cached
      try {
        await _groupService.updateGroup(_selectedGroup!);
      } catch (e) {
        debugPrint('Error updating group members: $e');
      }
    }
  }

  // Clear selected group
  void clearSelectedGroup() {
    _selectedGroup = null;
    _groupExpenses = [];
    notifyListeners();
  }

  // Calculate split
  Map<String, double> calculateSplit() {
    if (_selectedGroup == null) return {};
    return _groupService.calculateSplit(_selectedGroup!);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
