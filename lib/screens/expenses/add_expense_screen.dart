import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool isIncome;
  final ExpenseModel? expense; // For editing

  const AddExpenseScreen({super.key, this.isIncome = false, this.expense});

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
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _type = widget.isIncome ? ExpenseType.income : ExpenseType.expense;

    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _descriptionController.text = widget.expense!.description ?? '';
      _type = widget.expense!.type;
      _category = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    } else {
      _category = widget.isIncome
          ? ExpenseCategory.salary
          : ExpenseCategory.food;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final now = DateTime.now();
    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    ExpenseModel expense = ExpenseModel(
      id: widget.expense?.id ?? '',
      userId: authProvider.user!.uid,
      amount: amount,
      type: _type,
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;
    if (widget.expense != null) {
      success = await expenseProvider.updateExpense(expense);
    } else {
      success = await expenseProvider.addExpense(expense);

      // Update user balance
      if (success) {
        final balanceChange = _type == ExpenseType.income ? amount : -amount;
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
                  ? 'Cập nhật thành công'
                  : 'Thêm thành công',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expenseProvider.error ?? 'Đã có lỗi xảy ra'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Sửa ${_type == ExpenseType.income ? "Thu Nhập" : "Chi Tiêu"}'
              : 'Thêm ${_type == ExpenseType.income ? "Thu Nhập" : "Chi Tiêu"}',
        ),
        backgroundColor: _type == ExpenseType.income
            ? AppColors.incomeColor
            : AppColors.expenseColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              if (!isEditing) ...[
                _buildTypeSelector(),
                const SizedBox(height: 24),
              ],

              // Amount
              Text(
                AppStrings.amount,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '₫',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  if (double.tryParse(value.replaceAll(',', '')) == null) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category
              Text(
                AppStrings.category,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryGrid(),
              const SizedBox(height: 24),

              // Date
              Text(
                AppStrings.date,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textHint),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                AppStrings.description,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả (không bắt buộc)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == ExpenseType.income
                        ? AppColors.incomeColor
                        : AppColors.expenseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          AppStrings.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _type = ExpenseType.expense;
                _category = ExpenseCategory.food;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _type == ExpenseType.expense
                    ? AppColors.expenseColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == ExpenseType.expense
                      ? AppColors.expenseColor
                      : AppColors.textHint,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: _type == ExpenseType.expense
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chi tiêu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _type == ExpenseType.expense
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _type = ExpenseType.income;
                _category = ExpenseCategory.salary;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _type == ExpenseType.income
                    ? AppColors.incomeColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _type == ExpenseType.income
                      ? AppColors.incomeColor
                      : AppColors.textHint,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: _type == ExpenseType.income
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thu nhập',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _type == ExpenseType.income
                          ? Colors.white
                          : AppColors.textSecondary,
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

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _category == category;
        return GestureDetector(
          onTap: () => setState(() => _category = category),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _getCategoryColor(category).withValues(alpha: 0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _getCategoryColor(category)
                    : AppColors.textHint,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  ExpenseModel.getCategoryName(category),
                  style: TextStyle(fontSize: 10, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
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
      case ExpenseCategory.bonus:
        return AppColors.incomeColor;
      case ExpenseCategory.other:
        return AppColors.otherColor;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.bills:
        return Icons.receipt;
      case ExpenseCategory.health:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.salary:
        return Icons.account_balance;
      case ExpenseCategory.bonus:
        return Icons.card_giftcard;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}
