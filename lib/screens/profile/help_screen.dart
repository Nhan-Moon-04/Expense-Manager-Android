import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ Giúp'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn cần giúp đỡ?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ section
            Text(
              'Câu Hỏi Thường Gặp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              question: 'Làm sao để thêm chi tiêu mới?',
              answer:
                  'Bạn vào tab "Chi Tiêu" rồi nhấn nút "+" ở góc dưới bên phải. '
                  'Điền thông tin khoản chi tiêu và nhấn "Lưu".',
            ),
            _buildFaqItem(
              question: 'Làm sao để tạo nhóm chi tiêu?',
              answer:
                  'Vào tab "Nhóm", nhấn nút "+" để tạo nhóm mới. '
                  'Bạn có thể thêm thành viên bằng cách chia sẻ mã nhóm hoặc mời qua email.',
            ),
            _buildFaqItem(
              question: 'Dữ liệu có được đồng bộ không?',
              answer:
                  'Có, tất cả dữ liệu được lưu trên Firebase Cloud và tự động '
                  'đồng bộ giữa các thiết bị khi bạn đăng nhập cùng tài khoản.',
            ),
            _buildFaqItem(
              question: 'Làm sao để đổi mật khẩu?',
              answer:
                  'Vào "Cá Nhân" → "Đổi Mật Khẩu". Nhập mật khẩu hiện tại '
                  'và mật khẩu mới để thay đổi.',
            ),
            _buildFaqItem(
              question: 'Làm sao để xem thống kê chi tiêu?',
              answer:
                  'Ở Trang Chủ, bạn có thể xem tổng quan chi tiêu theo tháng. '
                  'Nhấn vào biểu đồ để xem chi tiết theo danh mục.',
            ),
            _buildFaqItem(
              question: 'Nhắc nhở chi tiêu hoạt động như nào?',
              answer:
                  'Bạn có thể tạo nhắc nhở ở Trang Chủ bằng cách nhấn vào mục "Nhắc Nhở". '
                  'Ứng dụng sẽ gửi thông báo vào thời gian bạn đã đặt.',
            ),
            const SizedBox(height: 28),

            // Contact support section
            Text(
              'Liên Hệ Hỗ Trợ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.facebook_rounded,
              color: const Color(0xFF1877F2),
              title: 'Facebook',
              subtitle: 'Nhắn tin qua Facebook Messenger',
              onTap: () => _launchUrl('https://www.facebook.com/thiennhan1611'),
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF0068FF),
              title: 'Zalo',
              subtitle: 'Chat trực tiếp qua Zalo: 0989057191',
              onTap: () => _launchUrl('https://zalo.me/0989057191'),
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              icon: Icons.phone_rounded,
              color: AppColors.success,
              title: 'Gọi điện',
              subtitle: '0989057191',
              onTap: () => _launchUrl('tel:0989057191'),
            ),
            const SizedBox(height: 10),
            _buildContactCard(
              icon: Icons.bug_report_rounded,
              color: AppColors.warning,
              title: 'Báo lỗi trên GitHub',
              subtitle: 'Nhan-Moon-04',
              onTap: () => _launchUrl('https://github.com/Nhan-Moon-04'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.help_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
