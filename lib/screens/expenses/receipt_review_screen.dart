import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/wallet_provider.dart';
import 'add_expense_screen.dart';

/// Phase 1.7 – Receipt Review Screen
/// Previews captured/selected receipt image with zoom & pan,
/// displays extracted OCR fields with confidence indicators,
/// and allows editing before confirming transaction creation.
class ReceiptReviewScreen extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final double? initialAmount;
  final String? initialMerchant;
  final DateTime? initialDate;
  final ExpenseCategory? initialCategory;
  final double? initialVat;
  final String? defaultWalletId;
  final Map<String, double>? confidences;

  const ReceiptReviewScreen({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.initialAmount,
    this.initialMerchant,
    this.initialDate,
    this.initialCategory,
    this.initialVat,
    this.defaultWalletId,
    this.confidences,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _vatController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  String? _selectedWalletId;
  bool _isSaving = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  // Confidence thresholds
  late final double _amountConfidence;
  late final double _merchantConfidence;

  @override
  void initState() {
    super.initState();

    final amt = widget.initialAmount ?? 0.0;
    _amountController = TextEditingController(
      text: amt > 0 ? _currencyFormatter.format(amt.toInt()) : '',
    );
    _merchantController = TextEditingController(
      text: widget.initialMerchant ?? 'Hóa đơn mua sắm',
    );
    _vatController = TextEditingController(
      text: widget.initialVat != null && widget.initialVat! > 0
          ? _currencyFormatter.format(widget.initialVat!.toInt())
          : '',
    );
    _noteController = TextEditingController();

    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedCategory = widget.initialCategory ?? ExpenseCategory.shopping;
    _selectedWalletId = widget.defaultWalletId;

    _amountConfidence = widget.confidences?['amount'] ?? (amt > 0 ? 0.92 : 0.40);
    _merchantConfidence =
        widget.confidences?['merchant'] ?? (widget.initialMerchant != null ? 0.88 : 0.60);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _vatController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseFormattedAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.value = const TextEditingValue(text: '');
      return;
    }
    final numVal = int.tryParse(clean) ?? 0;
    final formatted = _currencyFormatter.format(numVal);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openFullScreenImage() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: widget.imageFile != null
                    ? Image.file(widget.imageFile!)
                    : (widget.imageUrl != null
                        ? Image.network(widget.imageUrl!)
                        : const SizedBox.shrink()),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 10,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetailForm() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final parsedAmount = _parseFormattedAmount(_amountController.text);
    final targetWalletId = _selectedWalletId ?? walletProvider.primaryWallet?.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          isIncome: false,
          initialAmount: parsedAmount > 0 ? parsedAmount : null,
          initialDescription: _merchantController.text.trim(),
          initialReceiptUrl: widget.imageUrl,
          initialCategory: _selectedCategory,
          initialDate: _selectedDate,
          defaultWalletId: targetWalletId,
        ),
      ),
    );
  }

  Future<void> _quickSave() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = _parseFormattedAmount(_amountController.text);
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập số tiền hợp lệ (> 0đ)'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    if (authProvider.user == null) return;

    setState(() => _isSaving = true);

    final targetWalletId = _selectedWalletId ?? walletProvider.primaryWallet?.id;
    final now = DateTime.now();

    final expense = ExpenseModel(
      id: '',
      userId: authProvider.user!.uid,
      amount: parsedAmount,
      type: ExpenseType.expense,
      category: _selectedCategory,
      description: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : 'Chi tiêu theo hóa đơn',
      date: _selectedDate,
      createdAt: now,
      updatedAt: now,
      walletId: targetWalletId,
      receiptUrl: widget.imageUrl,
    );

    final success = await expenseProvider.addExpense(expense);
    if (success) {
      await authProvider.updateBalance(-parsedAmount);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        final lastExpenseId = expenseProvider.expenses.firstOrNull?.id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu chi tiêu từ hóa đơn thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: lastExpenseId != null
                ? SnackBarAction(
                    label: 'Hoàn tác',
                    textColor: Colors.white,
                    onPressed: () {
                      expenseProvider.deleteExpense(lastExpenseId);
                    },
                  )
                : null,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expenseProvider.error ?? 'Lỗi khi lưu giao dịch'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallets = walletProvider.wallets;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Xem lại hóa đơn',
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Chụp lại'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 1. RECEIPT IMAGE PREVIEW WITH ZOOM ───
                    _buildImagePreview(),

                    const SizedBox(height: 16),

                    // ─── 2. AI RECOGNITION STATUS BANNER ───
                    _buildAiBanner(),

                    const SizedBox(height: 16),

                    // ─── 3. AMOUNT CARD (HERO) ───
                    _buildAmountCard(),

                    const SizedBox(height: 16),

                    // ─── 4. BASIC INFO (STORE, DATE, VAT) ───
                    _buildStoreDateCard(),

                    const SizedBox(height: 16),

                    // ─── 5. CATEGORY & WALLET SELECTION ───
                    _buildCategoryAndWalletCard(wallets),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ─── BOTTOM ACTION BAR ───
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ─── 1. RECEIPT IMAGE PREVIEW WIDGET ───
  Widget _buildImagePreview() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1,
        ),
        boxShadow: AppShadows.subtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Zoomable viewer
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.5,
              child: widget.imageFile != null
                  ? Image.file(
                      widget.imageFile!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : (widget.imageUrl != null
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
                        )),
            ),
          ),

          // Zoom prompt badge
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pinch_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Chụm 2 ngón tay để phóng to',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Fullscreen expand button
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: _openFullScreenImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. AI RECOGNITION STATUS BANNER ───
  Widget _buildAiBanner() {
    final bool hasLowConfidence =
        _amountConfidence < 0.8 || _merchantConfidence < 0.8;
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasLowConfidence
            ? (isDark ? const Color(0xFF3E2805) : const Color(0xFFFEF3C7))
            : (isDark ? const Color(0xFF063321) : const Color(0xFFECFDF5)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasLowConfidence
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.success.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasLowConfidence
                ? Icons.warning_amber_rounded
                : Icons.auto_awesome_rounded,
            color: hasLowConfidence ? AppColors.warning : AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLowConfidence
                      ? 'Cần xác nhận lại thông tin'
                      : 'AI đã trích xuất dữ liệu thành công',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasLowConfidence
                        ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                        : (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLowConfidence
                      ? 'Các ô viền vàng có độ tin cậy thấp, hãy chỉnh sửa nếu cần'
                      : 'Độ tin cậy cao (${(_amountConfidence * 100).toInt()}%). Vui lòng kiểm tra lại trước khi lưu',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: hasLowConfidence
                        ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. AMOUNT CARD (HERO) ───
  Widget _buildAmountCard() {
    final bool isLowConf = _amountConfidence < 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isLowConf ? AppColors.warning : AppColors.dividerColor,
          width: isLowConf ? 1.5 : 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số tiền thanh toán',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _buildConfidenceBadge(_amountConfidence),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: _onAmountChanged,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.expenseColor,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                '₫',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. BASIC INFO CARD (STORE, DATE, VAT) ───
  Widget _buildStoreDateCard() {
    final bool isStoreLowConf = _merchantConfidence < 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store / Merchant field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cửa hàng / Đơn vị bán',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _buildConfidenceBadge(_merchantConfidence),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isStoreLowConf ? AppColors.warning : AppColors.dividerColor,
                width: isStoreLowConf ? 1.5 : 1.0,
              ),
            ),
            child: TextFormField(
              controller: _merchantController,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.storefront_rounded,
                  color: isStoreLowConf ? AppColors.warning : AppColors.primary,
                  size: 20,
                ),
                hintText: 'Tên cửa hàng, siêu thị...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date and VAT row
          Row(
            children: [
              // Date picker tile
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày trên hóa đơn',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputFillColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // VAT / Surcharge (optional)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thuế VAT',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.dividerColor,
                        ),
                      ),
                      child: TextFormField(
                        controller: _vatController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0 ₫',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. CATEGORY & WALLET SELECTION CARD ───
  Widget _buildCategoryAndWalletCard(List wallets) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.dividerColor,
          width: 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet selector
          Text(
            'Ví thanh toán',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFillColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.dividerColor,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null),
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                items: wallets.map<DropdownMenuItem<String>>((w) {
                  return DropdownMenuItem<String>(
                    value: w.id,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          w.name,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currencyFormatter.format(w.balance.toInt())} ₫',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWalletId = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Category Chips
          Text(
            'Danh mục chi tiêu gợi ý',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip(ExpenseCategory.food, 'Ăn uống', Icons.restaurant_rounded),
              _buildCategoryChip(ExpenseCategory.shopping, 'Mua sắm', Icons.shopping_bag_rounded),
              _buildCategoryChip(ExpenseCategory.transport, 'Di chuyển', Icons.directions_car_rounded),
              _buildCategoryChip(ExpenseCategory.entertainment, 'Giải trí', Icons.movie_rounded),
              _buildCategoryChip(ExpenseCategory.bills, 'Hóa đơn', Icons.receipt_long_rounded),
              _buildCategoryChip(ExpenseCategory.health, 'Y tế', Icons.medical_services_rounded),
              _buildCategoryChip(ExpenseCategory.other, 'Khác', Icons.more_horiz_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    ExpenseCategory cat,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = cat),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.inputFillColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.dividerColor,
        ),
      ),
    );
  }

  // ─── CONFIDENCE BADGE HELPER ───
  Widget _buildConfidenceBadge(double conf) {
    final isLow = conf < 0.8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            size: 12,
            color: isLow ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            isLow ? 'Độ tin cậy ${(conf * 100).toInt()}%' : 'Chính xác ${(conf * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLow ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM ACTION BAR ───
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Button 1: Edit in detailed form
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _navigateToDetailForm,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Sửa chi tiết'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Button 2: Quick Save & Confirm
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _quickSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Xác nhận & Lưu',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
