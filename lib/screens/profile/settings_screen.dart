import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auto_expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/backup_service.dart';
import '../../services/version_service.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  bool _isUploadingAvatar = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isExporting = false;
  bool _isDeletingAll = false;
  String _currentVersion = '';
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutoExpenseProvider>().checkNotificationAccess();
    });
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _currentVersion = info.version);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildAccountSection(),
                      const SizedBox(height: 24),
                      _buildAutoExpenseSection(),
                      const SizedBox(height: 24),
                      _buildNotificationsSection(),
                      const SizedBox(height: 24),
                      _buildDisplaySection(),
                      const SizedBox(height: 24),
                      _buildDataSection(),
                      const SizedBox(height: 24),
                      _buildDangerSection(),
                      const SizedBox(height: 24),
                      _buildAboutSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Tài khoản', Icons.person_rounded),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildAvatarTile(user.avatarUrl, user.fullName),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildListTile(
                icon: Icons.person_outline_rounded,
                title: 'Tên hiển thị',
                subtitle: user.fullName,
                onTap: () => _showEditNameDialog(user.fullName),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildListTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user.email,
                onTap: () {}, // Email cannot be changed
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildAvatarTile(String? avatarUrl, String fullName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildAvatarPlaceholder(fullName),
                          errorWidget: (context, url, error) =>
                              _buildAvatarPlaceholder(fullName),
                        )
                      : _buildAvatarPlaceholder(fullName),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploadingAvatar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh đại diện',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấn vào biểu tượng camera để thay đổi',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thay đổi ảnh đại diện',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildAvatarOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Chọn từ thư viện',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 12),
                _buildAvatarOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Chụp ảnh mới',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _buildAvatarOptionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Xóa ảnh đại diện',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chọn ảnh');
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    setState(() => _isUploadingAvatar = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      // Upload to Cloudinary
      final avatarUrl = await _cloudinaryService.uploadUserAvatar(
        imageFile,
        user.uid,
      );

      if (avatarUrl != null) {
        // Update user in Firestore
        final updatedUser = user.copyWith(
          avatarUrl: avatarUrl,
          updatedAt: DateTime.now(),
        );
        await authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Đã cập nhật ảnh đại diện')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Không thể tải ảnh lên');
      }
    } catch (e) {
      _showErrorSnackBar('Đã xảy ra lỗi khi cập nhật ảnh');
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isUploadingAvatar = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      // Update user in Firestore with null avatar
      await authProvider.updateUserAvatar(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Đã xóa ảnh đại diện')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Không thể xóa ảnh đại diện');
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Thay đổi tên hiển thị',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên của bạn',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                Navigator.pop(context);
                await _updateDisplayName(newName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDisplayName(String newName) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      final updatedUser = user.copyWith(
        fullName: newName,
        updatedAt: DateTime.now(),
      );
      await authProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Đã cập nhật tên hiển thị')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Không thể cập nhật tên');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildAutoExpenseSection() {
    return Consumer<AutoExpenseProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Tự động ghi chi tiêu',
              Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildMainAutoExpenseToggle(provider),
              if (provider.isEnabled) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAutoExpenseOption(
                  title: 'Tự động thêm chi tiêu',
                  subtitle: 'Ghi nhận khi có giao dịch chi tiêu',
                  value: provider.autoAddExpense,
                  onChanged: provider.setAutoAddExpense,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildAutoExpenseOption(
                  title: 'Tự động thêm thu nhập',
                  subtitle: 'Ghi nhận khi có giao dịch thu nhập',
                  value: provider.autoAddIncome,
                  onChanged: provider.setAutoAddIncome,
                ),
              ],
            ]),
            if (!provider.isNotificationAccessGranted && provider.isEnabled)
              _buildPermissionWarning(provider),
            const SizedBox(height: 12),
            _buildSupportedAppsInfo(),
          ],
        );
      },
    );
  }

  Widget _buildMainAutoExpenseToggle(AutoExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: provider.isEnabled
            ? const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.isEnabled
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: provider.isEnabled ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đọc thông báo ngân hàng',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: provider.isEnabled
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tự động ghi chi tiêu từ MoMo, VCB, MB...',
                  style: TextStyle(
                    fontSize: 13,
                    color: provider.isEnabled
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: provider.isEnabled,
            onChanged: (value) => provider.setEnabled(value),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoExpenseOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(AutoExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cần cấp quyền',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Cho phép đọc thông báo để tự động ghi nhận',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.requestNotificationAccess(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cấp quyền',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedAppsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ứng dụng được hỗ trợ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAppChip('MoMo'),
              _buildAppChip('Vietcombank'),
              _buildAppChip('MB Bank'),
              _buildAppChip('Techcombank'),
              _buildAppChip('BIDV'),
              _buildAppChip('TPBank'),
              _buildAppChip('VietinBank'),
              _buildAppChip('ACB'),
              _buildAppChip('Sacombank'),
              _buildAppChip('Agribank'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.info,
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Thông báo', Icons.notifications_rounded),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded,
            title: 'Thông báo chung',
            subtitle: 'Nhận thông báo từ ứng dụng',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildSwitchTile(
            icon: Icons.alarm_rounded,
            title: 'Nhắc nhở',
            subtitle: 'Nhận thông báo nhắc nhở chi tiêu',
            value: _reminderEnabled,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.science_rounded,
            title: 'Test thông báo',
            subtitle: 'Gửi thông báo test ngay lập tức',
            onTap: _testNotification,
          ),
        ]),
      ],
    );
  }

  Future<void> _testNotification() async {
    try {
      await PushNotificationService().showReminderNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🔔 Test thông báo',
        body: 'Nếu bạn thấy thông báo này, push notification đang hoạt động!',
        payload: 'test',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã gửi thông báo test'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildDisplaySection() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Hiển thị', Icons.palette_rounded),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildListTile(
                icon: Icons.attach_money_rounded,
                title: AppStrings.currency,
                subtitle: settings.currencyDisplayName,
                onTap: _showCurrencyPicker,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildListTile(
                icon: Icons.language_rounded,
                title: AppStrings.language,
                subtitle: settings.languageDisplayName,
                onTap: _showLanguagePicker,
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Dữ liệu', Icons.storage_rounded),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildListTile(
            icon: Icons.cloud_upload_rounded,
            title: 'Sao lưu dữ liệu',
            subtitle: 'Sao lưu lên đám mây',
            onTap: _isBackingUp ? () {} : _performBackup,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.cloud_download_rounded,
            title: 'Khôi phục dữ liệu',
            subtitle: 'Khôi phục từ bản sao lưu',
            onTap: _isRestoring ? () {} : _showRestoreDialog,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildListTile(
            icon: Icons.download_rounded,
            title: 'Xuất báo cáo',
            subtitle: 'Xuất dữ liệu ra file CSV',
            onTap: _isExporting ? () {} : _performExport,
          ),
        ]),
      ],
    );
  }

  Widget _buildDangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Vùng nguy hiểm',
          Icons.warning_rounded,
          color: AppColors.error,
        ),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildListTile(
            icon: Icons.delete_forever_rounded,
            title: 'Xóa tất cả dữ liệu',
            subtitle: 'Xóa vĩnh viễn tất cả dữ liệu',
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: _isDeletingAll ? () {} : _showDeleteDataDialog,
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chọn loại tiền tệ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPickerOption(
                  'VND',
                  'Việt Nam Đồng (₫)',
                  settings.currency == 'VND',
                  () async {
                    await settings.setCurrency('VND');
                    await _syncSettingsToFirestore();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _buildPickerOption(
                  'USD',
                  'US Dollar (\$)',
                  settings.currency == 'USD',
                  () async {
                    await settings.setCurrency('USD');
                    await _syncSettingsToFirestore();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _buildPickerOption(
                  'EUR',
                  'Euro (€)',
                  settings.currency == 'EUR',
                  () async {
                    await settings.setCurrency('EUR');
                    await _syncSettingsToFirestore();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chọn ngôn ngữ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPickerOption(
                  'vi',
                  'Tiếng Việt',
                  settings.language == 'vi',
                  () async {
                    await settings.setLanguage('vi');
                    await _syncSettingsToFirestore();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _buildPickerOption(
                  'en',
                  'English',
                  settings.language == 'en',
                  () async {
                    await settings.setLanguage('en');
                    await _syncSettingsToFirestore();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncSettingsToFirestore() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      final updatedUser = user.copyWith(
        settings: settings.toSettingsMap(),
        updatedAt: DateTime.now(),
      );
      await authProvider.updateUser(updatedUser);
    } catch (_) {}
  }

  Future<void> _performBackup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isBackingUp = true);
    try {
      await _backupService.backupToCloud(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Đã sao lưu dữ liệu thành công')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi sao lưu: $e');
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  void _showRestoreDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restore_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Khôi phục dữ liệu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Dữ liệu hiện tại sẽ được gộp với bản sao lưu. Bạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isRestoring = true);
    try {
      final result = await _backupService.restoreFromCloud(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đã khôi phục ${result['expenses']} chi tiêu, '
                    '${result['notes']} ghi chú, '
                    '${result['reminders']} nhắc nhở',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('$e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _performExport() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isExporting = true);
    try {
      final filePath = await _backupService.exportToExcel(
        user.uid,
        settings.currencyFormat,
      );
      if (mounted) {
        // Share the file
        await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi xuất file: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildPickerOption(
    String code,
    String name,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.background,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa tất cả dữ liệu',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Hệ thống sẽ tự động sao lưu dữ liệu ra file trước khi xóa.\n\n'
          'Tất cả chi tiêu, ghi chú, nhắc nhở, thông báo và nhóm sẽ bị xóa vĩnh viễn. '
          'Tài khoản đăng nhập sẽ được giữ lại. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performDeleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAllData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isDeletingAll = true);

    try {
      // Step 1: Backup to local file first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Đang sao lưu dữ liệu trước khi xóa...')),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 30),
        ),
      );

      final backupPath = await _backupService.backupToLocalFile(user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Step 2: Share the backup file
      await SharePlus.instance.share(ShareParams(files: [XFile(backupPath)]));

      if (!mounted) return;

      // Step 3: Show loading and delete all data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Đang xóa tất cả dữ liệu...')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 30),
        ),
      );

      final result = await _backupService.deleteAllUserData(user.uid);

      if (!mounted) return;

      // Clear all local provider data so the UI updates immediately
      Provider.of<ExpenseProvider>(context, listen: false).clearAllData();
      Provider.of<NoteProvider>(context, listen: false).clearAllData();
      Provider.of<ReminderProvider>(context, listen: false).clearAllData();
      Provider.of<NotificationProvider>(context, listen: false).clearAllData();
      Provider.of<GroupProvider>(context, listen: false).clearAllData();
      await Provider.of<AuthProvider>(context, listen: false).resetBalance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã xóa ${result['expenses']} chi tiêu, '
                  '${result['notes']} ghi chú, '
                  '${result['reminders']} nhắc nhở, '
                  '${result['groups']} nhóm.\n'
                  'File backup đã được lưu.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Lỗi xóa dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isDeletingAll = false);
    }
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Thông tin', Icons.info_rounded),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildListTile(
            icon: Icons.update_rounded,
            title: 'Phiên bản',
            subtitle: _currentVersion.isNotEmpty
                ? 'v$_currentVersion'
                : 'Đang tải...',
            onTap: () => _checkForUpdate(),
          ),
        ]),
      ],
    );
  }

  Future<void> _checkForUpdate() async {
    // Hiện loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Đang kiểm tra phiên bản...')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await VersionService().checkForUpdate();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.status == UpdateStatus.upToDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Bạn đang dùng phiên bản mới nhất!')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      UpdateDialog.checkAndShow(context);
    }
  }
}
