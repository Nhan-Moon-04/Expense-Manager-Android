import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/admin_colors.dart';
import '../../providers/scheduled_reminder_provider.dart';

class ScheduledReminderTab extends StatefulWidget {
  const ScheduledReminderTab({super.key});

  @override
  State<ScheduledReminderTab> createState() => _ScheduledReminderTabState();
}

class _ScheduledReminderTabState extends State<ScheduledReminderTab> {
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _messageController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ScheduledReminderProvider>();
      provider.loadConfig().then((_) {
        if (mounted) {
          _titleController.text = provider.title;
          _messageController.text = provider.message;
          setState(() => _isInitialized = true);
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduledReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !_isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfigCard(provider),
              const SizedBox(height: 20),
              _buildPreviewCard(provider),
              const SizedBox(height: 20),
              _buildSendCard(provider),
              if (provider.lastResult != null) ...[
                const SizedBox(height: 20),
                _buildResultCard(provider),
              ],
              const SizedBox(height: 20),
              _buildInfoCard(),
            ],
          ),
        );
      },
    );
  }

  // ==================== CẤU HÌNH ====================
  Widget _buildConfigCard(ScheduledReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AdminColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cấu Hình Nhắc Nhở',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Toggle bật/tắt
              Switch(
                value: provider.enabled,
                onChanged: (value) => provider.updateEnabled(value),
                activeTrackColor: AdminColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chọn giờ
          Row(
            children: [
              const Text(
                'Thời gian nhắc nhở:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _pickTime(provider),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AdminColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AdminColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AdminColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.timeDisplay,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'mỗi ngày',
                style: TextStyle(
                  fontSize: 14,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tiêu đề
          TextField(
            controller: _titleController,
            onChanged: provider.updateTitle,
            decoration: InputDecoration(
              labelText: 'Tiêu đề thông báo',
              hintText: 'Nhắc nhở ghi chép chi tiêu',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AdminColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nội dung
          TextField(
            controller: _messageController,
            onChanged: provider.updateMessage,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Nội dung thông báo',
              hintText: 'Bạn chưa ghi chép chi tiêu hôm nay...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.message),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AdminColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nút lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      await provider.saveConfig();
                      if (context.mounted) {
                        _showSnackBar(
                          provider.successMessage ??
                              provider.errorMessage ??
                              '',
                          isError: provider.errorMessage != null,
                        );
                        provider.clearMessages();
                      }
                    },
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(provider.isLoading ? 'Đang lưu...' : 'Lưu Cấu Hình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Hiển thị thông báo
          if (provider.successMessage != null || provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (provider.errorMessage != null
                              ? AdminColors.error
                              : AdminColors.success)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.errorMessage != null
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: provider.errorMessage != null
                          ? AdminColors.error
                          : AdminColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage ?? provider.successMessage ?? '',
                        style: TextStyle(
                          color: provider.errorMessage != null
                              ? AdminColors.error
                              : AdminColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== PREVIEW ====================
  Widget _buildPreviewCard(ScheduledReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.preview,
                  color: AdminColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Xem Trước',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: provider.isCheckingPreview
                    ? null
                    : () => provider.previewInactiveUsers(),
                icon: provider.isCheckingPreview
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  provider.isCheckingPreview
                      ? 'Đang kiểm tra...'
                      : 'Kiểm Tra Ngay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Danh sách user chưa có giao dịch hôm nay:',
            style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (provider.previewUsers.isEmpty && !provider.isCheckingPreview)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Nhấn "Kiểm Tra Ngay" để xem danh sách',
                  style: TextStyle(color: AdminColors.textHint, fontSize: 13),
                ),
              ),
            ),

          if (provider.previewUsers.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${provider.previewUsers.length} user',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'chưa có giao dịch hôm nay',
                          style: TextStyle(
                            fontSize: 13,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.previewUsers.length,
                      itemBuilder: (context, index) {
                        final user = provider.previewUsers[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AdminColors.accent.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (user['fullName'] as String?)
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  '?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AdminColors.accent,
                              ),
                            ),
                          ),
                          title: Text(
                            user['fullName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            user['email'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== GỬI NHẮC NHỞ ====================
  Widget _buildSendCard(ScheduledReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send,
                  color: AdminColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Gửi Nhắc Nhở Ngay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kiểm tra tất cả user và gửi nhắc nhở cho những ai chưa có giao dịch hôm nay. '
            'Thông báo sẽ dùng tiêu đề và nội dung đã cấu hình ở trên.',
            style: TextStyle(
              fontSize: 13,
              color: AdminColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          if (provider.isSending) ...[
            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.sendTotal > 0
                    ? provider.sendProgress / provider.sendTotal
                    : null,
                backgroundColor: AdminColors.accent.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AdminColors.accent,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang xử lý: ${provider.sendProgress}/${provider.sendTotal} user...',
              style: const TextStyle(
                fontSize: 13,
                color: AdminColors.textSecondary,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmAndSend(provider),
                icon: const Icon(Icons.notification_important),
                label: const Text('Kiểm Tra & Gửi Nhắc Nhở'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== KẾT QUẢ ====================
  Widget _buildResultCard(ScheduledReminderProvider provider) {
    final result = provider.lastResult!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AdminColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kết Quả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  'Tổng kiểm tra',
                  '${result['checked'] ?? 0}',
                  AdminColors.info,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  'Đã gửi nhắc nhở',
                  '${result['sent'] ?? 0}',
                  AdminColors.warning,
                  Icons.notifications_active,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  'Bỏ qua (đã giao dịch)',
                  '${result['skipped'] ?? 0}',
                  AdminColors.success,
                  Icons.check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==================== INFO ====================
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AdminColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Hướng dẫn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('1.', 'Cấu hình thời gian, tiêu đề và nội dung nhắc nhở.'),
          _infoRow('2.', 'Nhấn "Lưu Cấu Hình" để lưu lại cài đặt.'),
          _infoRow(
            '3.',
            'Nhấn "Kiểm Tra Ngay" ở mục Xem Trước để xem danh sách user chưa giao dịch.',
          ),
          _infoRow(
            '4.',
            'Nhấn "Kiểm Tra & Gửi Nhắc Nhở" để gửi thông báo cho tất cả user chưa có giao dịch hôm nay.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AdminColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Để tự động gửi nhắc nhở mỗi ngày, bạn cần triển khai Cloud Functions '
                    'trên Firebase. Cấu hình ở đây sẽ được Cloud Functions đọc để thực hiện.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AdminColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AdminColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  Future<void> _pickTime(ScheduledReminderProvider provider) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: provider.hour, minute: provider.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AdminColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      provider.updateTime(time.hour, time.minute);
    }
  }

  Future<void> _confirmAndSend(ScheduledReminderProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notification_important, color: AdminColors.warning),
            SizedBox(width: 8),
            Text('Xác nhận gửi nhắc nhở'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hệ thống sẽ:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _dialogStep('1', 'Kiểm tra tất cả user đang hoạt động'),
            _dialogStep('2', 'Tìm user chưa có giao dịch hôm nay'),
            _dialogStep('3', 'Gửi thông báo nhắc nhở cho các user đó'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiêu đề: ${provider.title}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nội dung: ${provider.message}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Gửi Ngay'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.sendRemindersNow();
    }
  }

  Widget _dialogStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AdminColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AdminColors.error : AdminColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
