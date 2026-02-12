import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_user_service.dart';

class AdminUserProvider extends ChangeNotifier {
  final AdminUserService _userService = AdminUserService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<UserModel> get users => _searchQuery.isEmpty ? _users : _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  StreamSubscription? _usersSubscription;

  /// Bắt đầu lắng nghe users stream
  void listenToUsers() {
    _isLoading = true;
    notifyListeners();

    _usersSubscription?.cancel();
    _usersSubscription = _userService.getUsersStream().listen(
      (users) {
        _users = users;
        _applySearch();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Tìm kiếm users
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = _users;
      return;
    }

    String lower = _searchQuery.toLowerCase();
    _filteredUsers = _users.where((user) {
      return user.fullName.toLowerCase().contains(lower) ||
          user.email.toLowerCase().contains(lower) ||
          (user.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  /// Bật/tắt user
  Future<bool> toggleUserActive(String uid, bool isActive) async {
    try {
      await _userService.toggleUserActive(uid, isActive);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Gửi email cấp lại mật khẩu
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _userService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật role
  Future<bool> updateUserRole(String uid, String role) async {
    try {
      await _userService.updateUserRole(uid, role);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}
