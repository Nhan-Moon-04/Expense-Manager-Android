import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService = AdminAuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _admin;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get admin => _admin;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AdminAuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      _admin = await _authService.getCurrentAdmin();
      if (_admin != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _admin = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _admin = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
