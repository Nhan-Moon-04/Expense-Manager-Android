import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../constants/app_colors.dart';

class SettleUpQrSheet extends StatefulWidget {
  final String debtorName;
  final String creditorName;
  final double amount;
  final String groupName;
  final String? bankAccountNo;
  final String? bankName;

  const SettleUpQrSheet({
    super.key,
    required this.debtorName,
    required this.creditorName,
    required this.amount,
    required this.groupName,
    this.bankAccountNo,
    this.bankName,
  });

  static Future<void> show(
    BuildContext context, {
    required String debtorName,
    required String creditorName,
    required double amount,
    required String groupName,
    String? bankAccountNo,
    String? bankName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettleUpQrSheet(
        debtorName: debtorName,
        creditorName: creditorName,
        amount: amount,
        groupName: groupName,
        bankAccountNo: bankAccountNo,
        bankName: bankName,
      ),
    );
  }

  @override
  State<SettleUpQrSheet> createState() => _SettleUpQrSheetState();
}

class _SettleUpQrSheetState extends State<SettleUpQrSheet> {
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  // Common Bank BIN map
  final Map<String, String> _bankBins = {
    'vietcombank': '970436',
    'vcb': '970436',
    'techcombank': '970407',
    'tcb': '970407',
    'mbbank': '970422',
    'mb': '970422',
    'vietinbank': '970415',
    'bidv': '970418',
    'tpbank': '970423',
    'acb': '970416',
    'vpbank': '970432',
  };

  @override
  void initState() {
    super.initState();
    _bankAccountController = TextEditingController(text: widget.bankAccountNo ?? '103874928192');
    _bankNameController = TextEditingController(text: widget.bankName ?? 'MBBank');
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  String _getVietQrUrl() {
    final cleanBank = _bankNameController.text.trim().toLowerCase();
    final bin = _bankBins[cleanBank] ?? '970422'; // Default MBBank
    final accountNo = _bankAccountController.text.trim();
    final amountInt = widget.amount.toInt();
    final note = Uri.encodeComponent('Tra tien nhom ${widget.groupName}');
    final accountName = Uri.encodeComponent(widget.creditorName);

    return 'https://img.vietqr.io/image/$bin-$accountNo-compact2.png?amount=$amountInt&addInfo=$note&accountName=$accountName';
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _getVietQrUrl();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quyết Toán Trả Nợ Nhóm',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Debt Relationship Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Người trả', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              widget.debtorName,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Người nhận', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              widget.creditorName,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số tiền thanh toán:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          '${_currencyFormat.format(widget.amount)} ₫',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // VietQR Code Image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: qrUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.qr_code_rounded, size: 80, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quét mã trên bất kỳ App Ngân Hàng nào để chuyển khoản ngay',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Copy Account Button
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _bankAccountController.text.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép số tài khoản!'), backgroundColor: AppColors.success),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('Sao chép STK: ${_bankAccountController.text}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 12),

              // Confirm Paid Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã ghi nhận thanh toán quyết toán nợ nhóm thành công!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    'Đã Thanh Toán Xong',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
