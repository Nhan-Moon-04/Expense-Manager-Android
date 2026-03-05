import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/expense_model.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;
    final isExpense = expense.type == ExpenseType.expense;
    final color = isExpense ? AppColors.expenseColor : AppColors.incomeColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.transactionDetail),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    expense: expense,
                    isIncome: expense.type == ExpenseType.income,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    expense.hasBankSource
                        ? Icons.account_balance_rounded
                        : _getCategoryIcon(expense.category),
                    color: Colors.white,
                    size: 48,
                  ),
                  if (expense.hasBankSource) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense.bankName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${isExpense ? "-" : "+"}${currencyFormat.format(expense.amount)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isExpense ? AppStrings.expense : AppStrings.income,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailCard([
                    _buildDetailItem(
                      icon: Icons.category,
                      label: AppStrings.category,
                      value: expense.displayName,
                    ),
                    if (expense.hasBankSource)
                      _buildDetailItem(
                        icon: Icons.account_balance_rounded,
                        label: AppStrings.source,
                        value: '${AppStrings.autoFromBank} ${expense.bankName}',
                      ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: AppStrings.date,
                      value: DateFormat(
                        'EEEE, dd/MM/yyyy',
                        AppLocalizations.currentLanguage,
                      ).format(expense.date),
                    ),
                    if (expense.description != null &&
                        expense.description!.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.notes,
                        label: AppStrings.description,
                        value: expense.description!,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailCard([
                    _buildDetailItem(
                      icon: Icons.access_time,
                      label: AppStrings.createdAt,
                      value: DateFormat(
                        'HH:mm - dd/MM/yyyy',
                      ).format(expense.createdAt),
                    ),
                    _buildDetailItem(
                      icon: Icons.update,
                      label: AppStrings.updatedAt,
                      value: DateFormat(
                        'HH:mm - dd/MM/yyyy',
                      ).format(expense.updatedAt),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
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
