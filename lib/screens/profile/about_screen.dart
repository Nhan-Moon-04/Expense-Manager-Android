import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Text('Về Ứng Dụng'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Phiên bản ${AppStrings.appVersion}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ứng dụng quản lý chi tiêu thông minh, giúp bạn theo dõi '
                    'và kiểm soát tài chính cá nhân một cách hiệu quả. '
                    'Hỗ trợ quản lý nhóm, ghi chú, nhắc nhở và thống kê chi tiết.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Developer info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                      Icon(Icons.code_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Nhà Phát Triển',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    label: 'Facebook',
                    value: 'Thiện Nhân',
                    onTap: () =>
                        _launchUrl('https://www.facebook.com/thiennhan1611'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF0068FF),
                    label: 'Zalo',
                    value: '0989057191',
                    onTap: () => _launchUrl('https://zalo.me/0989057191'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    icon: Icons.phone_rounded,
                    color: AppColors.success,
                    label: 'Điện thoại',
                    value: '0989057191',
                    onTap: () => _launchUrl('tel:0989057191'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    icon: Icons.code_rounded,
                    color: const Color(0xFF333333),
                    label: 'GitHub',
                    value: 'Nhan-Moon-04',
                    onTap: () => _launchUrl('https://github.com/Nhan-Moon-04'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Copyright
            Text(
              '© 2024-2026 ${AppStrings.appName}',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: 4),
            Text(
              'Made with ❤️ in Vietnam',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textHint),
        ],
      ),
    );
  }
}
