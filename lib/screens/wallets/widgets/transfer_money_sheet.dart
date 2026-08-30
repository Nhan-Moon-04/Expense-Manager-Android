import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../models/wallet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/wallet_provider.dart';

class TransferMoneySheet extends StatefulWidget {
  final String? initialSourceWalletId;

  const TransferMoneySheet({super.key, this.initialSourceWalletId});

  static Future<void> show(BuildContext context, {String? initialSourceWalletId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferMoneySheet(
        initialSourceWalletId: initialSourceWalletId,
      ),
    );
  }

  @override
  State<TransferMoneySheet> createState() => _TransferMoneySheetState();
}

class _TransferMoneySheetState extends State<TransferMoneySheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  String? _fromWalletId;
  String? _toWalletId;
  bool _isTransferring = false;

  final List<int> _quickAmounts = [100000, 200000, 500000, 1000000, 2000000, 5000000];

  @override
  void initState() {
    super.initState();
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallets = walletProvider.wallets;

    if (wallets.isNotEmpty) {
      _fromWalletId = widget.initialSourceWalletId ?? walletProvider.primaryWallet?.id ?? wallets.first.id;
      // Pick a different wallet for target if possible
      final otherWallets = wallets.where((w) => w.id != _fromWalletId).toList();
      if (otherWallets.isNotEmpty) {
        _toWalletId = otherWallets.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) return;
    final clean = val.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) {
      _amountController.clear();
      return;
    }
    final numVal = int.tryParse(clean);
    if (numVal != null) {
      final formatted = _currencyFormatter.format(numVal);
      if (formatted != val) {
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  void _addQuickAmount(int amountToAdd) {
    final clean = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final current = int.tryParse(clean) ?? 0;
    final updated = current + amountToAdd;
    final formatted = _currencyFormatter.format(updated);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _handleTransfer() async {
    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn cả ví nguồn và ví nhận'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ví nguồn và ví nhận không thể trùng nhau'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final clean = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(clean);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    if (authProvider.user == null) return;

    setState(() => _isTransferring = true);

    final success = await walletProvider.transferMoney(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      userId: authProvider.user!.uid,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      expenseProvider: expenseProvider,
    );

    if (mounted) {
      setState(() => _isTransferring = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyển tiền giữa các ví thành công!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(walletProvider.error ?? 'Lỗi khi chuyển tiền'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
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
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Chuyển Tiền Giữa Các Ví',
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
              const SizedBox(height: 20),

              // ─── FROM & TO WALLET SELECTOR ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    // From Wallet
                    _buildWalletDropdown(
                      label: 'Từ ví (Nguồn)',
                      selectedWalletId: _fromWalletId,
                      wallets: wallets,
                      icon: Icons.upload_rounded,
                      iconColor: AppColors.error,
                      onChanged: (id) => setState(() => _fromWalletId = id),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    // To Wallet
                    _buildWalletDropdown(
                      label: 'Đến ví (Đích)',
                      selectedWalletId: _toWalletId,
                      wallets: wallets,
                      icon: Icons.download_rounded,
                      iconColor: AppColors.success,
                      onChanged: (id) => setState(() => _toWalletId = id),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── AMOUNT INPUT ───
              Text(
                'Số tiền cần chuyển',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onAmountChanged,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(Icons.monetization_on_rounded, color: AppColors.primary),
                  suffixText: '₫',
                  suffixStyle: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Amount Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _quickAmounts.map((amt) {
                    final label = amt >= 1000000 ? '+${amt ~/ 1000000}tr' : '+${amt ~/ 1000}k';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.cardBackground,
                        side: BorderSide(color: AppColors.borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _addQuickAmount(amt),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Note Input
              Text(
                'Ghi chú (Tùy chọn)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Nạp tiền vào MoMo, Rút tiền ATM...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Button
              Container(
                width: double.infinity,
                height: 52,
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
                  onPressed: _isTransferring ? null : _handleTransfer,
                  icon: _isTransferring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _isTransferring ? 'Đang thực hiện...' : 'Xác Nhận Chuyển Tiền',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

  Widget _buildWalletDropdown({
    required String label,
    required String? selectedWalletId,
    required List<WalletModel> wallets,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWalletId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: wallets.map((w) {
                    return DropdownMenuItem<String>(
                      value: w.id,
                      child: Text(
                        w.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
