import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Delay load to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenToNotifications(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.notifications),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final notificationProvider = Provider.of<NotificationProvider>(
                context,
                listen: false,
              );

              if (value == 'markAllRead') {
                await notificationProvider.markAllAsRead(
                  authProvider.user!.uid,
                );
              } else if (value == 'deleteAll') {
                _showDeleteAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'markAllRead',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'deleteAll',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Xóa tất cả'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(
                notificationProvider.notifications[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            Provider.of<NotificationProvider>(
              context,
              listen: false,
            ).markAsRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? null
                : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.groupInvite:
        return AppColors.info;
      case NotificationType.groupExpense:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.promotion:
        return AppColors.accent;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.groupInvite:
        return Icons.group_add;
      case NotificationType.groupExpense:
        return Icons.receipt;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.promotion:
        return Icons.local_offer;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              Navigator.pop(context);
              await Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).deleteAllNotifications(authProvider.user!.uid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
