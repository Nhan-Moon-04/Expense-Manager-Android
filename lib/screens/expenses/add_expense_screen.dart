import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool isIncome;
  final ExpenseModel? expense; // Cho việc chỉnh sửa
  final String? defaultWalletId; // Ví mặc định
  final double? initialAmount;
  final String? initialDescription;
  final String? initialReceiptUrl;

  const AddExpenseScreen({
    super.key,
    this.isIncome = false,
    this.expense,
    this.defaultWalletId,
    this.initialAmount,
    this.initialDescription,
    this.initialReceiptUrl,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late ExpenseType _type;
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _receiptUrl;
  bool _isLoading = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  final List<ExpenseCategory> _expenseCategories = [
    ExpenseCategory.food,
    ExpenseCategory.transport,
    ExpenseCategory.shopping,
    ExpenseCategory.entertainment,
    ExpenseCategory.bills,
    ExpenseCategory.health,
    ExpenseCategory.education,
    ExpenseCategory.other,
  ];

  final List<ExpenseCategory> _incomeCategories = [
    ExpenseCategory.salary,
    ExpenseCategory.bonus,
    ExpenseCategory.other,
  ];

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _type = widget.isIncome ? ExpenseType.income : ExpenseType.expense;

    if (widget.expense != null) {
      final double val = widget.expense!.amount;
      _amountController.text = _formatNumber(val.toInt().toString());
      _descriptionController.text = widget.expense!.description ?? '';
      _type = widget.expense!.type;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
      _selectedWalletId = widget.expense!.walletId;
      _receiptUrl = widget.expense!.receiptUrl;
    } else {
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = _formatNumber(widget.initialAmount!.toInt().toString());
      }
      if (widget.initialDescription != null && widget.initialDescription!.isNotEmpty) {
        _descriptionController.text = widget.initialDescription!;
      }
      _receiptUrl = widget.initialReceiptUrl;
      _category = widget.isIncome
          ? ExpenseCategory.salary
          : ExpenseCategory.food;
      _selectedWalletId = widget.defaultWalletId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _categories =>
      _type == ExpenseType.income ? _incomeCategories : _expenseCategories;

  String _formatNumber(String s) {
    final clean = s.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return '';
    final val = int.tryParse(clean);
    if (val == null) return s;
    return _currencyFormatter.format(val);
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) return;
    final clean = val.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) {
      _amountController.clear();
      return;
    }
    final formatted = _formatNumber(clean);
    if (formatted != val) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _addQuickAmount(int amountToAdd) {
    final clean = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final current = int.tryParse(clean) ?? 0;
    final updated = current + amountToAdd;
    final formatted = _currencyFormatter.format(updated);

    setState(() {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  void _clearAmount() {
    setState(() {
      _amountController.clear();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _type == ExpenseType.income
                  ? AppColors.incomeColor
                  : AppColors.expenseColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final double? parsedAmount = double.tryParse(cleanAmount);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invalidAmount),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final walletId = _selectedWalletId ?? walletProvider.primaryWallet?.id;
    final now = DateTime.now();

    ExpenseModel expense = ExpenseModel(
      id: widget.expense?.id ?? '',
      userId: authProvider.user!.uid,
      amount: parsedAmount,
      type: _type,
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
      walletId: walletId,
      receiptUrl: _receiptUrl,
    );

    bool success;
    if (widget.expense != null) {
      success = await expenseProvider.updateExpense(expense);
    } else {
      success = await expenseProvider.addExpense(expense);

      if (success) {
        final balanceChange =
            _type == ExpenseType.income ? parsedAmount : -parsedAmount;
        await authProvider.updateBalance(balanceChange);
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense != null
                  ? AppStrings.updateSuccess
                  : AppStrings.addSuccess,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expenseProvider.error ?? AppStrings.errorOccurred),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final isIncome = _type == ExpenseType.income;
    final themeGradient =
        isIncome ? AppColors.incomeGradient : AppColors.expenseGradient;
    final themeColor = isIncome ? AppColors.incomeColor : AppColors.expenseColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ─── HERO HEADER BANNER ───
            _buildHeroHeader(isEditing, isIncome, themeGradient, themeColor),

            // ─── MAIN FORM BODY ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Phím tắt chọn nhanh số tiền
                    _buildQuickAmountChips(themeColor),
                    const SizedBox(height: 28),

                    // 2. Danh mục
                    _buildSectionTitle(
                      title: AppStrings.category,
                      icon: Icons.grid_view_rounded,
                      color: themeColor,
                    ),
                    const SizedBox(height: 14),
                    _buildCategoryGrid(),
                    const SizedBox(height: 28),

                    // 3. Ví tiền
                    _buildSectionTitle(
                      title: AppStrings.wallet,
                      icon: Icons.account_balance_wallet_rounded,
                      color: themeColor,
                    ),
                    const SizedBox(height: 14),
                    _buildWalletSelector(themeColor),
                    const SizedBox(height: 28),

                    // 4. Ngày tháng
                    _buildSectionTitle(
                      title: AppStrings.date,
                      icon: Icons.calendar_month_rounded,
                      color: themeColor,
                    ),
                    const SizedBox(height: 14),
                    _buildDateSelector(themeColor),
                    const SizedBox(height: 28),

                    // 5. Ghi chú
                    _buildSectionTitle(
                      title: AppStrings.description,
                      icon: Icons.edit_note_rounded,
                      color: themeColor,
                    ),
                    const SizedBox(height: 14),
                    _buildNoteInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ─── BOTTOM FLOATING SAVE BUTTON ───
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: themeColor.withValues(alpha: 0.4),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEditing
                                  ? AppStrings.save
                                  : (isIncome
                                      ? 'Thêm Thu Nhập'
                                      : 'Thêm Chi Tiêu'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HERO HEADER WIDGET ───
  Widget _buildHeroHeader(
    bool isEditing,
    bool isIncome,
    List<Color> themeGradient,
    Color themeColor,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row AppBar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút Back
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(10),
                ),
              ),

              // Segmented type selector (chỉ hiển thị khi tạo mới)
              if (!isEditing)
                _buildSegmentedTabSwitch()
              else
                Text(
                  isIncome ? AppStrings.income : AppStrings.expense,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

              // Spacer giữ cân bằng
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 24),

          // Label
          Center(
            child: Text(
              AppStrings.amount.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Input Số Tiền Hero Card (Glassmorphism design)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: _onAmountChanged,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    cursorColor: Colors.white,
                    cursorWidth: 2.5,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                ),
                Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEGMENTED SWITCH TAB ───
  Widget _buildSegmentedTabSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentTab(
            title: AppStrings.expense,
            icon: Icons.arrow_downward_rounded,
            isSelected: _type == ExpenseType.expense,
            onTap: () {
              setState(() {
                _type = ExpenseType.expense;
                _category = ExpenseCategory.food;
              });
            },
          ),
          _buildSegmentTab(
            title: AppStrings.income,
            icon: Icons.arrow_upward_rounded,
            isSelected: _type == ExpenseType.income,
            onTap: () {
              setState(() {
                _type = ExpenseType.income;
                _category = ExpenseCategory.salary;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (_type == ExpenseType.income
                      ? AppColors.incomeColor
                      : AppColors.expenseColor)
                  : Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK AMOUNT CHIPS ───
  Widget _buildQuickAmountChips(Color themeColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Nút Xóa
          GestureDetector(
            onTap: _clearAmount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.backspace_outlined,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Xóa',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Chips cộng tiền
          ..._quickAmounts.map((amt) {
            final formattedStr = '+${amt ~/ 1000}k';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _addQuickAmount(amt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    formattedStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── SECTION TITLE WIDGET ───
  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── CATEGORY GRID ───
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _category == category;
        final catColor = _getCategoryColor(category);

        return GestureDetector(
          onTap: () => setState(() => _category = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? catColor : AppColors.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor
                              : catColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? Colors.white : catColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ExpenseModel.getCategoryName(category),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? catColor
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── WALLET SELECTOR ───
  Widget _buildWalletSelector(Color themeColor) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallets = walletProvider.wallets;
        if (wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              AppStrings.primaryWallet,
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
          );
        }

        _selectedWalletId ??= walletProvider.primaryWallet?.id;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWalletId,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              items: wallets.map((wallet) {
                return DropdownMenuItem<String>(
                  value: wallet.id,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (wallet.isPrimary
                                  ? AppColors.primary
                                  : AppColors.secondary)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          wallet.isPrimary
                              ? Icons.account_balance_wallet_rounded
                              : Icons.wallet_rounded,
                          size: 18,
                          color: wallet.isPrimary
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (wallet.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.primaryBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedWalletId = value);
              },
            ),
          ),
        );
      },
    );
  }

  // ─── DATE SELECTOR ───
  Widget _buildDateSelector(Color themeColor) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Row(
      children: [
        // Chip Hôm nay
        _buildDateChip(
          label: 'Hôm nay',
          isSelected: _isToday,
          themeColor: themeColor,
          onTap: () => setState(() => _selectedDate = DateTime.now()),
        ),
        const SizedBox(width: 8),

        // Chip Hôm qua
        _buildDateChip(
          label: 'Hôm qua',
          isSelected: _isYesterday,
          themeColor: themeColor,
          onTap: () => setState(
            () => _selectedDate = DateTime.now().subtract(
              const Duration(days: 1),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Chip Custom Date Picker
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (!_isToday && !_isYesterday)
                    ? themeColor.withValues(alpha: 0.12)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (!_isToday && !_isYesterday)
                      ? themeColor
                      : AppColors.borderColor,
                  width: (!_isToday && !_isYesterday) ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: (!_isToday && !_isYesterday)
                        ? themeColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (!_isToday && !_isYesterday)
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: (!_isToday && !_isYesterday)
                          ? themeColor
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? themeColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─── NOTE INPUT ───
  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 2,
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.descriptionHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textHint,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10, top: 12),
            child: Column(
              children: [
                Icon(
                  Icons.notes_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
        ),
      ),
    );
  }

  // ─── CATEGORY HELPERS ───
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
      case ExpenseCategory.bonus:
        return AppColors.incomeColor;
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
        return Icons.widgets_rounded;
    }
  }
}
