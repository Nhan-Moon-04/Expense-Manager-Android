import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  User? get firebaseUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          _user = await _authService.getUserData(firebaseUser.uid);

          // Nếu user document chưa tồn tại, tạo mới
          if (_user == null) {
            _user = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              fullName:
                  firebaseUser.displayName ??
                  firebaseUser.email?.split('@')[0] ??
                  'User',
              phone: firebaseUser.phoneNumber,
              avatarUrl: firebaseUser.photoURL,
              totalBalance: 0,
              role: 'user',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _authService.createUserDocument(_user!);
          }
        } catch (e) {
          debugPrint('Error getting/creating user data: $e');
          _user = null;
        }
      } else {
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Đã có lỗi xảy ra. Vui lòng thử lại.');
      _setLoading(false);
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Đã có lỗi xảy ra. Vui lòng thử lại.');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _setError('Đã có lỗi xảy ra khi đăng xuất.');
    }
    _setLoading(false);
  }

  // Update user
  Future<bool> updateUser(UserModel updatedUser) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Đã có lỗi xảy ra khi cập nhật thông tin.');
      _setLoading(false);
      return false;
    }
  }

  // Update balance
  Future<void> updateBalance(double amount) async {
    if (_user == null) return;

    try {
      await _authService.updateBalance(_user!.uid, amount);
      _user = _user!.copyWith(totalBalance: _user!.totalBalance + amount);
      notifyListeners();
    } catch (e) {
      _setError('Đã có lỗi xảy ra khi cập nhật số dư.');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Đã có lỗi xảy ra. Vui lòng thử lại.');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Đã có lỗi xảy ra. Vui lòng thử lại.');
      _setLoading(false);
      return false;
    }
  }

  // Update user avatar (handles null for removal)
  Future<bool> updateUserAvatar(String? avatarUrl) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user == null) {
        _setLoading(false);
        return false;
      }

      await _authService.updateUserAvatar(_user!.uid, avatarUrl);
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        fullName: _user!.fullName,
        phone: _user!.phone,
        avatarUrl: avatarUrl,
        totalBalance: _user!.totalBalance,
        role: _user!.role,
        createdAt: _user!.createdAt,
        updatedAt: DateTime.now(),
        isActive: _user!.isActive,
        settings: _user!.settings,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Đã có lỗi xảy ra khi cập nhật ảnh đại diện.');
      _setLoading(false);
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (firebaseUser != null) {
      _user = await _authService.getUserData(firebaseUser!.uid);
      notifyListeners();
    }
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

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng bởi tài khoản khác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Hãy sử dụng ít nhất 6 ký tự.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      default:
        return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }
}
