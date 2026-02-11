import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../models/reminder_model.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReminders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<ReminderProvider>(
        context,
        listen: false,
      ).listenToReminders(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.reminders),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Đang hoạt động'),
            Tab(text: 'Đã hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReminderList(false), _buildReminderList(true)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReminderScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReminderList(bool showCompleted) {
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        final reminders = showCompleted
            ? reminderProvider.completedReminders
            : reminderProvider.activeReminders;

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  showCompleted
                      ? 'Chưa có nhắc nhở hoàn thành'
                      : 'Chưa có nhắc nhở nào',
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
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            return _buildReminderCard(reminders[index]);
          },
        );
      },
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    final isPast = reminder.reminderTime.isBefore(DateTime.now());
    final timeColor = isPast && !reminder.isCompleted
        ? AppColors.error
        : AppColors.textSecondary;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa nhắc nhở'),
            content: const Text('Bạn có chắc muốn xóa nhắc nhở này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppStrings.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        Provider.of<ReminderProvider>(
          context,
          listen: false,
        ).deleteReminder(reminder.id);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddReminderScreen(reminder: reminder),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () {
                  if (!reminder.isCompleted) {
                    Provider.of<ReminderProvider>(
                      context,
                      listen: false,
                    ).markAsCompleted(reminder.id);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reminder.isCompleted
                          ? AppColors.success
                          : AppColors.textHint,
                      width: 2,
                    ),
                    color: reminder.isCompleted
                        ? AppColors.success
                        : Colors.transparent,
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: reminder.isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: timeColor),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'HH:mm - dd/MM/yyyy',
                          ).format(reminder.reminderTime),
                          style: TextStyle(fontSize: 12, color: timeColor),
                        ),
                        if (reminder.repeat != ReminderRepeat.none) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ReminderModel.getRepeatName(reminder.repeat),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle
              Switch(
                value: reminder.isActive,
                onChanged: reminder.isCompleted
                    ? null
                    : (value) {
                        Provider.of<ReminderProvider>(
                          context,
                          listen: false,
                        ).toggleActive(reminder.id);
                      },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
