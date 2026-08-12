import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/widget_service.dart';

/// Model for a saved bank QR code
class BankQrItem {
  final String id;
  final String bankName;
  final String imagePath;
  bool isSelected;

  BankQrItem({
    required this.id,
    required this.bankName,
    required this.imagePath,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankName': bankName,
        'imagePath': imagePath,
        'isSelected': isSelected,
      };

  factory BankQrItem.fromJson(Map<String, dynamic> json) => BankQrItem(
        id: json['id'] as String,
        bankName: json['bankName'] as String,
        imagePath: json['imagePath'] as String,
        isSelected: json['isSelected'] as bool? ?? false,
      );
}

class QrBankSettingsScreen extends StatefulWidget {
  const QrBankSettingsScreen({super.key});

  @override
  State<QrBankSettingsScreen> createState() => _QrBankSettingsScreenState();
}

class _QrBankSettingsScreenState extends State<QrBankSettingsScreen> {
  static const String _prefsKey = 'qr_bank_list';

  List<BankQrItem> _qrList = [];
  bool _isLoading = true;

  final List<String> _bankOptions = [
    'VietinBank',
    'Vietcombank',
    'BIDV',
    'Agribank',
    'Techcombank',
    'MB Bank',
    'ACB',
    'TPBank',
    'Sacombank',
    'VPBank',
    'SHB',
    'HDBank',
    'OCB',
    'MSB',
    'VIB',
    'SeABank',
    'LienVietPostBank',
    'Eximbank',
    'Nam A Bank',
    'Bac A Bank',
    'MoMo',
    'ZaloPay',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadQrList();
  }

  Future<void> _loadQrList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _qrList = decoded.map((e) => BankQrItem.fromJson(e)).toList();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveQrList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_qrList.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }

  Future<void> _addQrCode() async {
    String? selectedBank;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
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
                  Text(
                    'Chọn Ngân Hàng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn ngân hàng rồi chọn ảnh QR Code',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _bankOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final bank = _bankOptions[index];
                        final isSelected = bank == selectedBank;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setSheetState(() => selectedBank = bank);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                        .withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getBankColor(bank)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        bank.substring(0, 1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: _getBankColor(bank),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      bank,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 15,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: selectedBank != null
                            ? () => Navigator.pop(context, selectedBank)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.textHint.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tiếp tục chọn ảnh QR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    // Pick QR image
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (image == null || !mounted) return;

    // Save to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${appDir.path}/qr_codes');
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = image.path.split('.').last;
    final savedPath = '${qrDir.path}/qr_$id.$ext';
    await File(image.path).copy(savedPath);

    final newItem = BankQrItem(
      id: id,
      bankName: result,
      imagePath: savedPath,
      isSelected: _qrList.isEmpty, // Auto-select first QR
    );

    setState(() => _qrList.add(newItem));
    await _saveQrList();

    // If first QR or auto-selected, update widget
    if (newItem.isSelected) {
      await _updateWidgetQr(savedPath);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Đã thêm QR $result')),
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
  }

  Future<void> _selectQr(BankQrItem item) async {
    setState(() {
      for (var qr in _qrList) {
        qr.isSelected = (qr.id == item.id);
      }
    });
    await _saveQrList();
    await _updateWidgetQr(item.imagePath);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.qr_code_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Đã chọn QR ${item.bankName} cho widget'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _deleteQr(BankQrItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa QR ${item.bankName}?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'QR Code này sẽ bị xóa vĩnh viễn.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Delete file
    try {
      final file = File(item.imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    final wasSelected = item.isSelected;
    setState(() => _qrList.removeWhere((q) => q.id == item.id));
    await _saveQrList();

    if (wasSelected) {
      if (_qrList.isNotEmpty) {
        _qrList.first.isSelected = true;
        await _saveQrList();
        await _updateWidgetQr(_qrList.first.imagePath);
      } else {
        await _updateWidgetQr(null);
      }
    }
  }

  Future<void> _updateWidgetQr(String? imagePath) async {
    await WidgetService().updateQrWidgetData(imagePath);
  }

  void _showFullQr(BankQrItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          item.bankName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quét mã QR để chuyển khoản',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.imagePath),
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        width: 280,
                        height: 280,
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBankColor(String bank) {
    switch (bank) {
      case 'VietinBank':
        return const Color(0xFF1A3C7E);
      case 'Vietcombank':
        return const Color(0xFF1B6E3D);
      case 'BIDV':
        return const Color(0xFF003B71);
      case 'Agribank':
        return const Color(0xFFE31837);
      case 'Techcombank':
        return const Color(0xFFE31837);
      case 'MB Bank':
        return const Color(0xFF1E4D9E);
      case 'ACB':
        return const Color(0xFF1A237E);
      case 'TPBank':
        return const Color(0xFF6A1B9A);
      case 'Sacombank':
        return const Color(0xFF1565C0);
      case 'VPBank':
        return const Color(0xFF00897B);
      case 'MoMo':
        return const Color(0xFFA50064);
      case 'ZaloPay':
        return const Color(0xFF0068FF);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                  Expanded(
                    child: Text(
                      'QR Ngân Hàng',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _qrList.isEmpty
                      ? _buildEmptyState()
                      : _buildQrList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQrCode,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm QR',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có QR ngân hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm QR Code ngân hàng để hiển thị trên widget\nvà cho phép người khác quét thanh toán nhanh',
              textAlign: TextAlign.center,
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

  Widget _buildQrList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _qrList.length,
      itemBuilder: (context, index) {
        final item = _qrList[index];
        return _buildQrCard(item);
      },
    );
  }

  Widget _buildQrCard(BankQrItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: item.isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2)
            : Border.all(color: AppColors.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: item.isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFullQr(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // QR Preview
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      File(item.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.inputFillColor,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getBankColor(item.bankName)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.bankName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getBankColor(item.bankName),
                              ),
                            ),
                          ),
                          if (item.isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.widgets_rounded,
                                    size: 10,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Widget',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.isSelected
                            ? 'Đang hiển thị trên widget'
                            : 'Nhấn để xem • Giữ để xóa',
                        style: TextStyle(
                          fontSize: 13,
                          color: item.isSelected
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    // Select for widget button
                    if (!item.isSelected)
                      GestureDetector(
                        onTap: () => _selectQr(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.radio_button_unchecked_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () => _deleteQr(item),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
