import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  NumberFormat get currencyFormat =>
      context.read<SettingsProvider>().currencyFormat;
  DateTime _selectedMonth = DateTime.now();
  String _filterType = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Delay _loadData to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final userId = authProvider.user!.uid;
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).loadDailySummary(userId, _selectedMonth.year, _selectedMonth.month);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    _loadData();
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses) {
    // First filter by wallet
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    var filtered = walletProvider.filterByWallet(expenses);

    // Filter by month
    filtered = filtered
        .where(
          (e) =>
              e.date.year == _selectedMonth.year &&
              e.date.month == _selectedMonth.month,
        )
        .toList();

    if (_filterType == 'income') {
      filtered = filtered.where((e) => e.type == ExpenseType.income).toList();
    } else if (_filterType == 'expense') {
      filtered = filtered.where((e) => e.type == ExpenseType.expense).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        final amount = e.amount.toString().contains(query);
        final desc = (e.description ?? '').toLowerCase().contains(query);
        final category = ExpenseModel.getCategoryName(
          e.category,
        ).toLowerCase().contains(query);
        final bankName = (e.bankName ?? '').toLowerCase().contains(query);
        return amount || desc || category || bankName;
      }).toList();
    }

    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          if (_isSearching) ...[
                            const SizedBox(height: 10),
                            _buildSearchBar(),
                          ],
                          const SizedBox(height: 12),
                          _buildSummaryCards(),
                          const SizedBox(height: 12),
                          _buildFilterChips(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _buildExpenseList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          AppStrings.expenses,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        _buildWalletSelector(),
        const Spacer(),
        _buildMonthSelectorButton(),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Icon(
              _isSearching ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showFilterDialog,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelectorButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _changeMonth(-1),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.chevron_left_rounded, size: 18),
            ),
          ),
          GestureDetector(
            onTap: _showMonthPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                DateFormat('MM/yy').format(_selectedMonth),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => _changeMonth(1),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppStrings.searchExpenseHint,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final selectedWallet = walletProvider.selectedWallet;
        final displayName = selectedWallet?.name ?? AppStrings.allWallets;

        return GestureDetector(
          onTap: () => _showWalletPicker(walletProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWalletPicker(WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  AppStrings.selectWallet,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "All" option
                        _buildWalletPickerOption(
                          name: AppStrings.allWallets,
                          icon: Icons.all_inclusive_rounded,
                          isSelected: walletProvider.selectedWalletId == null,
                          onTap: () {
                            walletProvider.setSelectedWallet(null);
                            Navigator.pop(context);
                          },
                        ),
                        ...walletProvider.wallets.map(
                          (wallet) => _buildWalletPickerOption(
                            name: wallet.name,
                            icon: wallet.isPrimary
                                ? Icons.account_balance_wallet_rounded
                                : Icons.wallet_rounded,
                            isSelected:
                                walletProvider.selectedWalletId == wallet.id,
                            isPrimary: wallet.isPrimary,
                            onTap: () {
                              walletProvider.setSelectedWallet(wallet.id);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildWalletPickerOption({
    required String name,
    required IconData icon,
    required bool isSelected,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.background,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppStrings.primaryBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer2<ExpenseProvider, WalletProvider>(
      builder: (context, expenseProvider, walletProvider, child) {
        final expenses = _filterExpenses(expenseProvider.expenses);
        final totalIncome = expenses
            .where((e) => e.type == ExpenseType.income)
            .fold(0.0, (sum, e) => sum + e.amount);
        final totalExpense = expenses
            .where((e) => e.type == ExpenseType.expense)
            .fold(0.0, (sum, e) => sum + e.amount);
        final balance = totalIncome - totalExpense;

        final isPositive = balance >= 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPositive
                  ? const [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                      Color(0xFF2563EB),
                    ]
                  : const [
                      Color(0xFF1F0712),
                      Color(0xFF4C0519),
                      Color(0xFF881337),
                      Color(0xFFE11D48),
                    ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPositive
                        ? const Color(0xFF312E81)
                        : const Color(0xFF881337))
                    .withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Month Balance & Eye Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.monthBalance} (${DateFormat('MM/yyyy').format(_selectedMonth)})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isBalanceVisible
                            ? Text(
                                currencyFormat.format(balance),
                                key: const ValueKey('vis'),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              )
                            : Text(
                                '••••••••',
                                key: const ValueKey('hid'),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row: Compact Split Income & Expense Badges
              Row(
                children: [
                  // Income Badge Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.south_west_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.income,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _isBalanceVisible
                                      ? currencyFormat.format(totalIncome)
                                      : '••••••',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF34D399),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Expense Badge Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF43F5E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.north_east_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.expense,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _isBalanceVisible
                                      ? currencyFormat.format(totalExpense)
                                      : '••••••',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFB7185),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('all', AppStrings.all, Icons.list_rounded),
        const SizedBox(width: 10),
        _buildFilterChip(
          'income',
          AppStrings.income,
          Icons.south_west_rounded,
        ),
        const SizedBox(width: 10),
        _buildFilterChip(
          'expense',
          AppStrings.expense,
          Icons.north_east_rounded,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterType == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filterType = value),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.shadowColor,
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer2<ExpenseProvider, WalletProvider>(
      builder: (context, expenseProvider, walletProvider, child) {
        final expenses = _filterExpenses(expenseProvider.expenses);

        if (expenses.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.noTransactions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.addFirstTransaction,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by date
        Map<String, List<ExpenseModel>> groupedExpenses = {};
        for (var expense in expenses) {
          String dateKey = DateFormat('dd/MM/yyyy').format(expense.date);
          groupedExpenses[dateKey] = groupedExpenses[dateKey] ?? [];
          groupedExpenses[dateKey]!.add(expense);
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            String dateKey = groupedExpenses.keys.elementAt(index);
            List<ExpenseModel> dateExpenses = groupedExpenses[dateKey]!;

            double dayIncome = dateExpenses
                .where((e) => e.type == ExpenseType.income)
                .fold(0.0, (sum, e) => sum + e.amount);
            double dayExpense = dateExpenses
                .where((e) => e.type == ExpenseType.expense)
                .fold(0.0, (sum, e) => sum + e.amount);

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              child: Column(
                children: [
                  // Date Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DateFormat('dd').format(dateExpenses.first.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDayName(dateExpenses.first.date),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMMM yyyy',
                                  'vi',
                                ).format(dateExpenses.first.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (dayIncome > 0)
                              Text(
                                '+${currencyFormat.format(dayIncome)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            if (dayExpense > 0)
                              Text(
                                '-${currencyFormat.format(dayExpense)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expense Items
                  ...dateExpenses.asMap().entries.map(
                    (entry) => _buildExpenseItem(
                      entry.value,
                      isLast: entry.key == dateExpenses.length - 1,
                    ),
                  ),
                ],
              ),
            );
          }, childCount: groupedExpenses.keys.length),
        );
      },
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense, {bool isLast = false}) {
    final isExpense = expense.type == ExpenseType.expense;
    final color = isExpense ? AppColors.expenseColor : AppColors.incomeColor;
    final categoryColor = _getCategoryColor(expense.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(color: AppColors.background, width: 1),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (expense.hasBankSource
                              ? _getBankColor(expense.bankSource!)
                              : categoryColor)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: expense.hasBankSource
                    ? Icon(
                        _getBankIcon(expense.bankSource!),
                        color: _getBankColor(expense.bankSource!),
                        size: 22,
                      )
                    : Icon(
                        _getCategoryIcon(expense.category),
                        color: categoryColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (expense.isAutoAdded) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppStrings.autoBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (expense.description != null &&
                        expense.description!.isNotEmpty)
                      Text(
                        expense.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Wallet name
                    Consumer<WalletProvider>(
                      builder: (context, walletProvider, _) {
                        final walletName = walletProvider.getWalletName(
                          expense.walletId,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wallet_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                walletName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"}${currencyFormat.format(expense.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(expense.date),
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'expense_list_fab',
        onPressed: () {
          final walletProvider = Provider.of<WalletProvider>(
            context,
            listen: false,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                defaultWalletId:
                    walletProvider.selectedWalletId ??
                    walletProvider.primaryWallet?.id,
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  AppStrings.filterTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFilterDialogOption(
                  'all',
                  AppStrings.allTransactions,
                  Icons.list_rounded,
                ),
                _buildFilterDialogOption(
                  'income',
                  AppStrings.incomeOnly,
                  Icons.arrow_downward_rounded,
                ),
                _buildFilterDialogOption(
                  'expense',
                  AppStrings.expenseOnly,
                  Icons.arrow_upward_rounded,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterDialogOption(String value, String label, IconData icon) {
    final isSelected = _filterType == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.background,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
        onTap: () {
          setState(() => _filterType = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return AppStrings.today;
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return AppStrings.yesterday;
    }

    return DateFormat('EEEE', AppLocalizations.currentLanguage).format(date);
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
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.salary:
        return Icons.account_balance_rounded;
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
        return const Color(0xFFAE2070); // MoMo pink
      case 'vcb':
      case 'vietcombank':
        return const Color(0xFF1B6E37); // VCB green
      case 'mbbank':
        return const Color(0xFF1E4DB7); // MB blue
      case 'techcombank':
        return const Color(0xFFED1C24); // TCB red
      case 'bidv':
        return const Color(0xFF2E3192); // BIDV blue
      case 'vietinbank':
        return const Color(0xFF1D4A94); // VietinBank blue
      case 'tpbank':
        return const Color(0xFF652D86); // TPBank purple
      case 'acb':
        return const Color(0xFF1A2B6D); // ACB dark blue
      case 'sacombank':
        return const Color(0xFF003087); // Sacombank blue
      case 'agribank':
        return const Color(0xFFE31837); // Agribank red
      default:
        return AppColors.primary;
    }
  }
}
