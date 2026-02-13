import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/admin_colors.dart';
import '../../constants/admin_strings.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_notification_provider.dart';
import '../../providers/admin_user_provider.dart';
import 'scheduled_reminder_tab.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminNotificationProvider>().listenToLogs();
      // Đảm bảo user provider đã lắng nghe
      final userProvider = context.read<AdminUserProvider>();
      if (userProvider.users.isEmpty) {
        userProvider.listenToUsers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AdminStrings.notifications,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AdminColors.accent,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.accent,
                  tabs: const [
                    Tab(text: 'Gửi Thông Báo'),
                    Tab(text: 'Nhắc Nhở Tự Động'),
                    Tab(text: 'Lịch Sử'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSendTab(),
              const ScheduledReminderTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SEND TAB ====================
  Widget _buildSendTab() {
    return _SendNotificationForm();
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab() {
    return Consumer<AdminNotificationProvider>(
      builder: (context, notifProvider, _) {
        if (notifProvider.isLoading && notifProvider.logs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notifProvider.logs.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử thông báo'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: notifProvider.logs.length,
          itemBuilder: (context, index) {
            final log = notifProvider.logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getStatusIcon(log.status),
                    color: _getStatusColor(log.status),
                    size: 20,
                  ),
                ),
                title: Text(
                  log.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      log.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _infoBadge(
                          log.target == 'all'
                              ? 'Tất cả'
                              : log.targetUserName ?? 'User',
                          AdminColors.info,
                        ),
                        _infoBadge(
                          '${log.sentCount}/${log.totalCount} lần',
                          AdminColors.accent,
                        ),
                        _infoBadge(
                          _getStatusText(log.status),
                          _getStatusColor(log.status),
                        ),
                        if (log.isContinuous)
                          _infoBadge(
                            'Liên tục (${log.intervalSeconds}s)',
                            AdminColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AdminColors.textHint,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AdminColors.error,
                    size: 20,
                  ),
                  onPressed: () => _confirmDeleteLog(log.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AdminColors.success;
      case 'sending':
        return AdminColors.warning;
      case 'cancelled':
        return AdminColors.error;
      default:
        return AdminColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'sending':
        return Icons.send;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'sending':
        return 'Đang gửi';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  void _confirmDeleteLog(String logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử?'),
        content: const Text('Bạn có chắc muốn xóa bản ghi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminNotificationProvider>().deleteLog(logId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ==================== SEND NOTIFICATION FORM ====================
class _SendNotificationForm extends StatefulWidget {
  @override
  State<_SendNotificationForm> createState() => _SendNotificationFormState();
}

class _SendNotificationFormState extends State<_SendNotificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _repeatController = TextEditingController(text: '1');
  final _intervalController = TextEditingController(text: '5');

  String _sendTarget = 'all'; // 'all' hoặc 'user'
  UserModel? _selectedUser;
  NotificationType _notificationType = NotificationType.system;
  bool _isContinuous = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _repeatController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sendTarget == 'user' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người dùng'),
          backgroundColor: AdminColors.error,
        ),
      );
      return;
    }

    final notifProvider = context.read<AdminNotificationProvider>();
    final adminId = context.read<AdminAuthProvider>().admin?.uid ?? '';
    bool success;

    if (_isContinuous) {
      int repeatCount = int.tryParse(_repeatController.text) ?? 1;
      int intervalSeconds = int.tryParse(_intervalController.text) ?? 5;

      success = await notifProvider.sendContinuously(
        adminId: adminId,
        userId: _sendTarget == 'user' ? _selectedUser?.uid : null,
        userName: _selectedUser?.fullName,
        title: _titleController.text,
        message: _messageController.text,
        type: _notificationType,
        repeatCount: repeatCount,
        intervalSeconds: intervalSeconds,
      );
    } else {
      if (_sendTarget == 'all') {
        success = await notifProvider.sendToAll(
          adminId: adminId,
          title: _titleController.text,
          message: _messageController.text,
          type: _notificationType,
        );
      } else {
        success = await notifProvider.sendToUser(
          adminId: adminId,
          userId: _selectedUser!.uid,
          userName: _selectedUser!.fullName,
          title: _titleController.text,
          message: _messageController.text,
          type: _notificationType,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Gửi thông báo thành công!' : 'Lỗi gửi thông báo',
          ),
          backgroundColor: success ? AdminColors.success : AdminColors.error,
        ),
      );

      if (success) {
        _titleController.clear();
        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminNotificationProvider>(
      builder: (context, notifProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sending progress indicator
                if (notifProvider.isSending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AdminColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AdminColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AdminColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đang gửi: ${notifProvider.sendProgress}/${notifProvider.sendTotal}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AdminColors.warning,
                              ),
                            ),
                            const Spacer(),
                            if (_isContinuous)
                              TextButton(
                                onPressed: () => notifProvider.cancelSending(),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(color: AdminColors.error),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: notifProvider.sendTotal > 0
                              ? notifProvider.sendProgress /
                                    notifProvider.sendTotal
                              : 0,
                          backgroundColor: AdminColors.warning.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            AdminColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Target selection
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đối tượng nhận',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _targetOption(
                            'all',
                            'Tất cả người dùng',
                            Icons.groups_rounded,
                          ),
                          const SizedBox(width: 12),
                          _targetOption(
                            'user',
                            'Chọn người dùng',
                            Icons.person_rounded,
                          ),
                        ],
                      ),
                      if (_sendTarget == 'user') ...[
                        const SizedBox(height: 12),
                        _buildUserSelector(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notification content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nội dung thông báo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<NotificationType>(
                        initialValue: _notificationType,
                        decoration: InputDecoration(
                          labelText: AdminStrings.notificationType,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AdminColors.background,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: NotificationType.system,
                            child: Text('Hệ thống'),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.promotion,
                            child: Text('Khuyến mãi'),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.reminder,
                            child: Text('Nhắc nhở'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _notificationType = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: AdminStrings.notificationTitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AdminColors.background,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: AdminStrings.notificationMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AdminColors.background,
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập nội dung';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Continuous sending options
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Gửi liên tục',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isContinuous,
                            activeThumbColor: AdminColors.accent,
                            onChanged: (value) {
                              setState(() => _isContinuous = value);
                            },
                          ),
                        ],
                      ),
                      if (_isContinuous) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Gửi thông báo nhiều lần với khoảng cách thời gian tuỳ chọn',
                          style: TextStyle(
                            color: AdminColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _repeatController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AdminStrings.repeatCount,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: AdminColors.background,
                                ),
                                validator: _isContinuous
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Bắt buộc';
                                        }
                                        int? count = int.tryParse(value);
                                        if (count == null || count < 1) {
                                          return 'Tối thiểu 1';
                                        }
                                        if (count > 100) {
                                          return 'Tối đa 100';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _intervalController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AdminStrings.intervalSeconds,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: AdminColors.background,
                                ),
                                validator: _isContinuous
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Bắt buộc';
                                        }
                                        int? sec = int.tryParse(value);
                                        if (sec == null || sec < 1) {
                                          return 'Tối thiểu 1s';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: notifProvider.isSending ? null : _handleSend,
                    icon: notifProvider.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      notifProvider.isSending
                          ? AdminStrings.sending
                          : AdminStrings.sendNotification,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _targetOption(String value, String label, IconData icon) {
    bool isSelected = _sendTarget == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sendTarget = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AdminColors.accent.withValues(alpha: 0.1)
                : AdminColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AdminColors.accent : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AdminColors.accent
                    : AdminColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AdminColors.accent
                      : AdminColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Consumer<AdminUserProvider>(
      builder: (context, userProvider, _) {
        List<UserModel> users = userProvider.users
            .where((u) => u.role != 'admin')
            .toList();

        return Autocomplete<UserModel>(
          displayStringForOption: (user) => '${user.fullName} (${user.email})',
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return users.take(10);
            }
            String lower = textEditingValue.text.toLowerCase();
            return users.where(
              (user) =>
                  user.fullName.toLowerCase().contains(lower) ||
                  user.email.toLowerCase().contains(lower),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Tìm và chọn người dùng',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AdminColors.background,
              ),
            );
          },
          onSelected: (user) {
            setState(() => _selectedUser = user);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                    maxWidth: 400,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      UserModel user = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AdminColors.accent.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AdminColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => onSelected(user),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
