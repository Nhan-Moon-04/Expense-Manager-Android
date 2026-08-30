import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/expense_model.dart';
import '../../services/vps_upload_service.dart';
import 'add_expense_screen.dart';
import 'widgets/quick_edit_auto_expense_sheet.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _isUploading = false;
  final VpsUploadService _vpsUploadService = VpsUploadService();

  Future<void> _captureAndUploadReceipt(ExpenseModel currentExpense) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chụp / Chọn Ảnh Hóa Đơn',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text('Chụp ảnh ngay', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Mở camera chụp biên lai / hóa đơn'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                ),
                title: Text('Chọn từ thư viện', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chọn ảnh đã chụp sẵn trong máy'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1920);
      if (picked == null) return;

      setState(() => _isUploading = true);

      final url = await _vpsUploadService.uploadImage(
        File(picked.path),
        folder: 'receipts',
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (url != null) {
          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
          final updated = currentExpense.copyWith(
            receiptUrl: url,
            updatedAt: DateTime.now(),
          );
          await expenseProvider.updateExpense(updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã lưu ảnh hóa đơn lên VPS thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải ảnh lên VPS. Vui lòng thử lại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteReceipt(ExpenseModel currentExpense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ảnh hóa đơn?'),
        content: const Text('Bạn có chắc muốn gỡ bỏ ảnh hóa đơn khỏi giao dịch này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final updated = currentExpense.copyWith(
        clearReceiptUrl: true,
        updatedAt: DateTime.now(),
      );
      await expenseProvider.updateExpense(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ảnh hóa đơn thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image_rounded, size: 60, color: Colors.white70),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;
    final allExpenses = context.watch<ExpenseProvider>().expenses;
    final expense = allExpenses.firstWhere(
      (e) => e.id == widget.expense.id,
      orElse: () => widget.expense,
    );

    final isExpense = expense.type == ExpenseType.expense;
    final accentColor = isExpense ? AppColors.expenseColor : AppColors.incomeColor;
    final categoryColor = _getCategoryColor(expense.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.transactionDetail,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (expense.isAutoAdded)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              tooltip: 'Bổ sung ghi chú & ảnh',
              onPressed: () => QuickEditAutoExpenseSheet.show(context, expense),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // ─── Digital Receipt Card Slip ───
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Receipt Top Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      children: [
                        // Merchant / Bank Avatar Circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: (expense.hasBankSource
                                    ? _getBankColor(expense.bankSource!)
                                    : categoryColor)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (expense.hasBankSource
                                      ? _getBankColor(expense.bankSource!)
                                      : categoryColor)
                                  .withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            expense.hasBankSource
                                ? _getBankIcon(expense.bankSource!)
                                : _getCategoryIcon(expense.category),
                            color: expense.hasBankSource
                                ? _getBankColor(expense.bankSource!)
                                : categoryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          expense.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Bank / Auto Badge
                        if (expense.hasBankSource) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flash_on_rounded,
                                  color: AppColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tự động từ ${expense.bankName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Large Crisp Amount
                        Text(
                          '${isExpense ? "-" : "+"}${currencyFormat.format(expense.amount)}',
                          style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Success Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Thành công',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed Slip Cut Line
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLinePainter(
                      color: AppColors.dividerColor,
                    ),
                  ),

                  // Receipt Line Items
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        _buildReceiptRow(
                          label: 'Loại giao dịch',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isExpense ? AppStrings.expense : AppStrings.income,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                        _buildReceiptRow(
                          label: AppStrings.category,
                          value: ExpenseModel.getCategoryName(expense.category),
                        ),
                        Consumer<WalletProvider>(
                          builder: (context, walletProvider, _) {
                            final walletName =
                                walletProvider.getWalletName(expense.walletId);
                            return _buildReceiptRow(
                              label: AppStrings.wallet,
                              value: walletName,
                              icon: Icons.account_balance_wallet_rounded,
                            );
                          },
                        ),
                        if (expense.hasBankSource)
                          _buildReceiptRow(
                            label: AppStrings.source,
                            value: expense.bankName!,
                            icon: Icons.account_balance_rounded,
                          ),
                        _buildReceiptRow(
                          label: AppStrings.date,
                          value: DateFormat(
                            'HH:mm - EEEE, dd/MM/yyyy',
                            AppLocalizations.currentLanguage,
                          ).format(expense.date),
                        ),

                        // Ghi chú người dùng
                        if (expense.description != null &&
                            expense.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppStrings.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (expense.isAutoAdded)
                                      GestureDetector(
                                        onTap: () => QuickEditAutoExpenseSheet.show(context, expense),
                                        child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expense.description!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Hiển thị nội dung gốc từ tin nhắn ngân hàng nếu đã sửa ghi chú
                        if (expense.metadata?['originalBankDescription'] != null &&
                            expense.metadata!['originalBankDescription'] != expense.description) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nội dung gốc ngân hàng:',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  expense.metadata!['originalBankDescription'],
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        // Transaction ID with Copy Button
                        _buildReceiptRow(
                          label: 'Mã giao dịch',
                          child: Row(
                            children: [
                              Text(
                                expense.id.length > 16
                                    ? '${expense.id.substring(0, 16)}...'
                                    : expense.id,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: expense.id),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép mã giao dịch'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ─── Image Receipt Section ───
                        const SizedBox(height: 16),
                        if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ảnh hóa đơn / Biên lai (Lưu trên VPS):',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFullScreenImage(expense.receiptUrl!),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: AppColors.surfaceVariant,
                                    child: CachedNetworkImage(
                                      imageUrl: expense.receiptUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => const Center(
                                        child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Xem đầy đủ',
                                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _deleteReceipt(expense),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                label: const Text('Xóa ảnh', style: TextStyle(color: AppColors.error)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _captureAndUploadReceipt(expense),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                label: const Text('Đổi ảnh khác'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (_isUploading)
                            Container(
                              height: 60,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(strokeWidth: 2.5),
                                  SizedBox(width: 12),
                                  Text('Đang tải ảnh lên VPS...'),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => _captureAndUploadReceipt(expense),
                              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                              label: const Text('Chụp / Đính kèm hóa đơn (Lưu lên VPS)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                minimumSize: const Size(double.infinity, 44),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Action Buttons Bar ───
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context, expense),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(AppStrings.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (expense.isAutoAdded) {
                          QuickEditAutoExpenseSheet.show(context, expense);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(
                                expense: expense,
                                isIncome: expense.type == ExpenseType.income,
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        expense.isAutoAdded ? Icons.edit_note_rounded : Icons.edit_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        expense.isAutoAdded ? 'Sửa & Thêm ảnh' : AppStrings.edit,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    String? value,
    Widget? child,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (child != null)
            child
          else
            Text(
              value ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.deleteTransaction),
        content: Text(AppStrings.deleteTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              final expenseProvider = Provider.of<ExpenseProvider>(
                context,
                listen: false,
              );
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              bool success = await expenseProvider.deleteExpense(expense.id);

              if (success) {
                // Revert balance
                final balanceChange = expense.type == ExpenseType.income
                    ? -expense.amount
                    : expense.amount;
                await authProvider.updateBalance(balanceChange);

                if (context.mounted) {
                  Navigator.pop(context); // Go back to list screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.transactionDeleted),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
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

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return AppColors.foodColor;
      case ExpenseCategory.transport:
        return AppColors.transportColor;
      case ExpenseCategory.shopping:
        return AppColors.shoppingColor;
      case ExpenseCategory.entertainment:
        return AppColors.entertainmentColor;
      case ExpenseCategory.bills:
        return AppColors.billsColor;
      case ExpenseCategory.health:
        return AppColors.healthColor;
      case ExpenseCategory.education:
        return AppColors.educationColor;
      case ExpenseCategory.salary:
        return AppColors.incomeColor;
      case ExpenseCategory.bonus:
        return AppColors.accent;
      case ExpenseCategory.other:
        return AppColors.otherColor;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.salary:
        return Icons.account_balance_wallet_rounded;
      case ExpenseCategory.bonus:
        return Icons.card_giftcard_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  IconData _getBankIcon(String bankSource) {
    switch (bankSource.toLowerCase()) {
      case 'momo':
        return Icons.account_balance_wallet_rounded;
      case 'vcb':
      case 'vietcombank':
        return Icons.account_balance_rounded;
      case 'mbbank':
        return Icons.account_balance_rounded;
      case 'techcombank':
        return Icons.account_balance_rounded;
      case 'bidv':
        return Icons.account_balance_rounded;
      case 'vietinbank':
        return Icons.account_balance_rounded;
      case 'tpbank':
        return Icons.account_balance_rounded;
      case 'acb':
        return Icons.account_balance_rounded;
      case 'sacombank':
        return Icons.account_balance_rounded;
      case 'agribank':
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _getBankColor(String bankSource) {
    switch (bankSource.toLowerCase()) {
      case 'momo':
        return const Color(0xFFAE2070);
      case 'vcb':
      case 'vietcombank':
        return const Color(0xFF1B6E37);
      case 'mbbank':
        return const Color(0xFF1E4DB7);
      case 'techcombank':
        return const Color(0xFFED1C24);
      case 'bidv':
        return const Color(0xFF2E3192);
      case 'vietinbank':
        return const Color(0xFF1D4A94);
      case 'tpbank':
        return const Color(0xFF652D86);
      case 'acb':
        return const Color(0xFF1A2B6D);
      case 'sacombank':
        return const Color(0xFF003087);
      case 'agribank':
        return const Color(0xFFE31837);
      default:
        return AppColors.primary;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 20;
    final endX = size.width - 20;

    while (startX < endX) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
