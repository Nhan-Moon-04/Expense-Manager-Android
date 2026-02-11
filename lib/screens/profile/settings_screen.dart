import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  String _currency = 'VND';
  String _language = 'vi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.settings),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications section
          _buildSectionHeader('Thông Báo'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Thông báo chung'),
              subtitle: const Text('Nhận thông báo từ ứng dụng'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              activeColor: AppColors.primary,
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Nhắc nhở'),
              subtitle: const Text('Nhận thông báo nhắc nhở chi tiêu'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() => _reminderEnabled = value);
              },
              activeColor: AppColors.primary,
            ),
          ]),
          const SizedBox(height: 16),

          // Display section
          _buildSectionHeader('Hiển Thị'),
          _buildSettingsCard([
            ListTile(
              title: Text(AppStrings.currency),
              subtitle: Text(_getCurrencyName()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCurrencyPicker,
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(AppStrings.language),
              subtitle: Text(_getLanguageName()),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguagePicker,
            ),
          ]),
          const SizedBox(height: 16),

          // Data section
          _buildSectionHeader('Dữ Liệu'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.cloud_upload, color: AppColors.primary),
              title: const Text('Sao lưu dữ liệu'),
              subtitle: const Text('Sao lưu lên đám mây'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.cloud_download, color: AppColors.primary),
              title: const Text('Khôi phục dữ liệu'),
              subtitle: const Text('Khôi phục từ bản sao lưu'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.download, color: AppColors.primary),
              title: const Text('Xuất báo cáo'),
              subtitle: const Text('Xuất dữ liệu ra file Excel'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),

          // Danger zone
          _buildSectionHeader('Vùng Nguy Hiểm'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                'Xóa tất cả dữ liệu',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text('Xóa vĩnh viễn tất cả dữ liệu'),
              onTap: _showDeleteDataDialog,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  String _getCurrencyName() {
    switch (_currency) {
      case 'VND':
        return 'Việt Nam Đồng (₫)';
      case 'USD':
        return 'US Dollar (\$)';
      case 'EUR':
        return 'Euro (€)';
      default:
        return _currency;
    }
  }

  String _getLanguageName() {
    switch (_language) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return _language;
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn loại tiền tệ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildCurrencyOption('VND', 'Việt Nam Đồng (₫)'),
              _buildCurrencyOption('USD', 'US Dollar (\$)'),
              _buildCurrencyOption('EUR', 'Euro (€)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    final isSelected = _currency == code;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(name),
      onTap: () {
        setState(() => _currency = code);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn ngôn ngữ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption('vi', 'Tiếng Việt'),
              _buildLanguageOption('en', 'English'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final isSelected = _language == code;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(name),
      onTap: () {
        setState(() => _language = code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng đang phát triển')),
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa tất cả dữ liệu',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Hành động này sẽ xóa vĩnh viễn tất cả dữ liệu của bạn và không thể khôi phục. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
