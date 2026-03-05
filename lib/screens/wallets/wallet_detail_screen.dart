import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wallet_model.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/settings_provider.dart';
import '../expenses/expense_detail_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late WalletModel _wallet;
  List<Map<String, dynamic>> _availableBanks = [];
  bool _isLoadingBanks = false;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _loadBankList();
  }

  Future<void> _loadBankList() async {
    setState(() => _isLoadingBanks = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/Nhan-Quyen/expense-manager-config/main/rule_bank.json',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final banks = (data['banks'] as List)
            .map(
              (b) => {
                'id': b['id'] as String,
                'name': b['name'] as String,
                'enabled': b['enabled'] ?? true,
              },
            )
            .toList();
        if (mounted) {
          setState(() {
            _availableBanks = banks;
            _isLoadingBanks = false;
          });
        }
      } else {
        // Fallback to local data
        _loadLocalBankList();
      }
    } catch (e) {
      _loadLocalBankList();
    }
  }

  void _loadLocalBankList() {
    setState(() {
      _availableBanks = [
        {'id': 'momo', 'name': 'MoMo', 'enabled': true},
        {'id': 'vcb', 'name': 'Vietcombank', 'enabled': true},
        {'id': 'mbbank', 'name': 'MB Bank', 'enabled': true},
        {'id': 'techcombank', 'name': 'Techcombank', 'enabled': true},
        {'id': 'bidv', 'name': 'BIDV', 'enabled': true},
        {'id': 'tpbank', 'name': 'TPBank', 'enabled': true},
        {'id': 'vietinbank', 'name': 'VietinBank', 'enabled': true},
        {'id': 'acb', 'name': 'ACB', 'enabled': true},
        {'id': 'sacombank', 'name': 'Sacombank', 'enabled': true},
        {'id': 'agribank', 'name': 'Agribank', 'enabled': true},
      ];
      _isLoadingBanks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer3<WalletProvider, ExpenseProvider, AuthProvider>(
            builder:
                (
                  context,
                  walletProvider,
                  expenseProvider,
                  authProvider,
                  child,
                ) {
                  // Get updated wallet data from provider
                  final updatedWallet = walletProvider.getWalletById(
                    _wallet.id,
                  );
                  if (updatedWallet != null) _wallet = updatedWallet;

                  final allExpenses = expenseProvider.expenses;
                  final walletExpenses = allExpenses
                      .where((e) => e.walletId == _wallet.id)
                      .toList();
                  final balance = walletProvider.getWalletBalance(
                    _wallet.id,
                    allExpenses,
                  );
                  final income = walletExpenses
                      .where((e) => e.type == ExpenseType.income)
                      .fold(0.0, (sum, e) => sum + e.amount);
                  final expense = walletExpenses
                      .where((e) => e.type == ExpenseType.expense)
                      .fold(0.0, (sum, e) => sum + e.amount);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildBalanceCard(
                                balance,
                                income,
                                expense,
                                currencyFormat,
                              ),
                              const SizedBox(height: 24),
                              _buildLinkedBanksSection(
                                walletProvider,
                                authProvider,
                              ),
                              const SizedBox(height: 24),
                              _buildTransactionsSection(
                                walletExpenses,
                                currencyFormat,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            _wallet.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditWalletDialog();
            } else if (value == 'delete') {
              _showDeleteWalletDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(AppStrings.editWallet),
                ],
              ),
            ),
            if (!_wallet.isPrimary)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.deleteWallet,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    double balance,
    double income,
    double expense,
    NumberFormat currencyFormat,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _wallet.isPrimary
              ? AppColors.primaryGradient
              : [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_wallet.isPrimary ? AppColors.primary : AppColors.secondary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.balance,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  AppStrings.income,
                  currencyFormat.format(income),
                  Icons.arrow_downward_rounded,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  AppStrings.expense,
                  currencyFormat.format(expense),
                  Icons.arrow_upward_rounded,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedBanksSection(
    WalletProvider walletProvider,
    AuthProvider authProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.linkedBanks,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddBankDialog(walletProvider, authProvider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppStrings.add),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_wallet.linkedBankIds.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textHint.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.noBanksAssigned,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bấm "Thêm" để gán ngân hàng',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ..._wallet.linkedBankIds.map((bankId) {
            final bankName = _getBankName(bankId);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                title: Text(
                  bankName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: () async {
                    final userId = authProvider.user!.uid;
                    await walletProvider.unlinkBank(userId, _wallet.id, bankId);
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTransactionsSection(
    List<ExpenseModel> expenses,
    NumberFormat currencyFormat,
  ) {
    final sortedExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentExpenses = sortedExpenses.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentTransactions,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (recentExpenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.noTransactions,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentExpenses.map(
            (expense) => _buildTransactionItem(expense, currencyFormat),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(
    ExpenseModel expense,
    NumberFormat currencyFormat,
  ) {
    final isExpense = expense.type == ExpenseType.expense;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isExpense ? AppColors.expenseColor : AppColors.incomeColor)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isExpense
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: isExpense ? AppColors.expenseColor : AppColors.incomeColor,
            size: 20,
          ),
        ),
        title: Text(
          expense.description ?? ExpenseModel.getCategoryName(expense.category),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat(
            'dd/MM/yyyy',
            AppLocalizations.currentLanguage,
          ).format(expense.date),
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}${currencyFormat.format(expense.amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isExpense ? AppColors.expenseColor : AppColors.incomeColor,
          ),
        ),
      ),
    );
  }

  String _getBankName(String bankId) {
    for (final bank in _availableBanks) {
      if (bank['id'] == bankId) return bank['name'] as String;
    }
    // Fallback
    switch (bankId) {
      case 'momo':
        return 'MoMo';
      case 'vcb':
        return 'Vietcombank';
      case 'mbbank':
        return 'MB Bank';
      case 'techcombank':
        return 'Techcombank';
      case 'bidv':
        return 'BIDV';
      case 'tpbank':
        return 'TPBank';
      case 'vietinbank':
        return 'VietinBank';
      case 'acb':
        return 'ACB';
      case 'sacombank':
        return 'Sacombank';
      case 'agribank':
        return 'Agribank';
      default:
        return bankId;
    }
  }

  void _showAddBankDialog(
    WalletProvider walletProvider,
    AuthProvider authProvider,
  ) {
    final searchController = TextEditingController();
    final userId = authProvider.user!.uid;

    // Get banks already linked to ANY wallet
    final allLinkedBanks = <String>{};
    for (final w in walletProvider.wallets) {
      allLinkedBanks.addAll(w.linkedBankIds);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filteredBanks = _availableBanks.where((bank) {
              final name = (bank['name'] as String).toLowerCase();
              final id = (bank['id'] as String).toLowerCase();
              return name.contains(query) || id.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.addBank,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppStrings.searchBankHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingBanks
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: filteredBanks.length,
                            itemBuilder: (context, index) {
                              final bank = filteredBanks[index];
                              final bankId = bank['id'] as String;
                              final bankName = bank['name'] as String;
                              final isLinked = allLinkedBanks.contains(bankId);
                              final isLinkedToThis = _wallet.linkedBankIds
                                  .contains(bankId);

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_rounded,
                                    color: AppColors.info,
                                    size: 20,
                                  ),
                                ),
                                title: Text(bankName),
                                trailing: isLinkedToThis
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                      )
                                    : isLinked
                                    ? Text(
                                        AppStrings.assigned,
                                        style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                enabled: !isLinked || isLinkedToThis,
                                onTap: isLinkedToThis
                                    ? null
                                    : isLinked
                                    ? null
                                    : () async {
                                        await walletProvider.linkBank(
                                          userId,
                                          _wallet.id,
                                          bankId,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${AppStrings.assigned} $bankName → ${_wallet.name}',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        }
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditWalletDialog() {
    final nameController = TextEditingController(text: _wallet.name);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.renameWallet),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: AppStrings.enterNewName,
            prefixIcon: const Icon(
              Icons.wallet_rounded,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final updated = _wallet.copyWith(
                name: name,
                updatedAt: DateTime.now(),
              );
              final success = await walletProvider.updateWallet(updated);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  setState(() => _wallet = updated);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.walletRenamed),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteWalletDialog() {
    if (_wallet.isPrimary) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.cannotDeletePrimary),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.deleteWallet),
        content: Text('${AppStrings.confirmDelete} "${_wallet.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await walletProvider.deleteWallet(
                authProvider.user!.uid,
                _wallet.id,
              );
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                if (success && this.context.mounted) {
                  Navigator.pop(this.context); // Go back to wallet list
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.walletDeleted),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
