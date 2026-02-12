import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/admin_colors.dart';
import '../../constants/admin_strings.dart';
import '../../models/user_model.dart';
import '../../providers/admin_user_provider.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().listenToUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUserProvider>(
      builder: (context, userProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AdminStrings.userManagement,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userProvider.users.length} người dùng',
                    style: const TextStyle(
                      color: AdminColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AdminStrings.searchUser,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  userProvider.search('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        userProvider.search(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // User list
            Expanded(
              child: userProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userProvider.users.isEmpty
                  ? const Center(child: Text('Không tìm thấy người dùng nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: userProvider.users.length,
                      itemBuilder: (context, index) {
                        return _buildUserCard(
                          userProvider.users[index],
                          userProvider,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, AdminUserProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: user.isActive
              ? AdminColors.accent.withValues(alpha: 0.1)
              : AdminColors.error.withValues(alpha: 0.1),
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: user.isActive
                        ? AdminColors.accent
                        : AdminColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (user.role == 'admin')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: AdminColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AdminColors.success.withValues(alpha: 0.1)
                    : AdminColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Disabled',
                style: TextStyle(
                  color: user.isActive
                      ? AdminColors.success
                      : AdminColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: AdminColors.textSecondary,
              ),
            ),
            Text(
              'Tham gia: ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AdminColors.textHint),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, user, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Chi tiết'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle_outline,
                    size: 18,
                    color: user.isActive
                        ? AdminColors.error
                        : AdminColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isActive
                        ? AdminStrings.disableUser
                        : AdminStrings.enableUser,
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset, size: 18, color: AdminColors.warning),
                  SizedBox(width: 8),
                  Text(AdminStrings.resetPassword),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetail(user),
      ),
    );
  }

  void _handleAction(
    String action,
    UserModel user,
    AdminUserProvider provider,
  ) {
    switch (action) {
      case 'detail':
        _showUserDetail(user);
        break;
      case 'toggle':
        _confirmToggle(user, provider);
        break;
      case 'reset_password':
        _confirmResetPassword(user, provider);
        break;
    }
  }

  void _showUserDetail(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailScreen(user: user),
    );
  }

  void _confirmToggle(UserModel user, AdminUserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isActive ? 'Vô hiệu hóa tài khoản?' : 'Kích hoạt tài khoản?',
        ),
        content: Text(
          user.isActive
              ? 'Người dùng "${user.fullName}" sẽ không thể đăng nhập.'
              : 'Người dùng "${user.fullName}" sẽ có thể đăng nhập lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.toggleUserActive(
                user.uid,
                !user.isActive,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã cập nhật trạng thái thành công'
                          : 'Lỗi cập nhật trạng thái',
                    ),
                    backgroundColor: success
                        ? AdminColors.success
                        : AdminColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive
                  ? AdminColors.error
                  : AdminColors.success,
            ),
            child: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
          ),
        ],
      ),
    );
  }

  void _confirmResetPassword(UserModel user, AdminUserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấp lại mật khẩu?'),
        content: Text(
          'Một email đổi mật khẩu sẽ được gửi đến "${user.email}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.sendPasswordReset(user.email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã gửi email đặt lại mật khẩu'
                          : 'Lỗi gửi email',
                    ),
                    backgroundColor: success
                        ? AdminColors.success
                        : AdminColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.warning,
            ),
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );
  }
}
