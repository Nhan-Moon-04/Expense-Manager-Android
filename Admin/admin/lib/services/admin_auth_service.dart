import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập admin - kiểm tra role = 'admin'
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        throw Exception('Đăng nhập thất bại');
      }

      // Kiểm tra role admin
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('Tài khoản không tồn tại trong hệ thống');
      }

      UserModel userModel = UserModel.fromFirestore(doc);

      if (userModel.role != 'admin') {
        await _auth.signOut();
        throw Exception('Bạn không có quyền truy cập Admin Panel');
      }

      if (!userModel.isActive) {
        await _auth.signOut();
        throw Exception('Tài khoản đã bị vô hiệu hóa');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Email không tồn tại');
        case 'wrong-password':
          throw Exception('Mật khẩu không đúng');
        case 'invalid-email':
          throw Exception('Email không hợp lệ');
        case 'user-disabled':
          throw Exception('Tài khoản đã bị vô hiệu hóa');
        case 'invalid-credential':
          throw Exception('Email hoặc mật khẩu không đúng');
        default:
          throw Exception('Lỗi đăng nhập: ${e.message}');
      }
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Lấy thông tin admin hiện tại
  Future<UserModel?> getCurrentAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;

    UserModel userModel = UserModel.fromFirestore(doc);
    if (userModel.role != 'admin') return null;

    return userModel;
  }
}
