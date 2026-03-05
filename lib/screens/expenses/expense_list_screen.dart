import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _buildWalletSelector(),
                          if (_isSearching) ...[
                            const SizedBox(height: 12),
                            _buildSearchBar(),
                          ],
                          const SizedBox(height: 20),
                          _buildMonthSelector(),
                          const SizedBox(height: 20),
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Quản lý giao dịch của bạn',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  onTap: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isSearching
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  onTap: _showFilterDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          hintText: 'Tìm số tiền, nội dung, ngân hàng, loại...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
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
        final displayName = selectedWallet?.name ?? 'Tất cả ví';

        return GestureDetector(
          onTap: () => _showWalletPicker(walletProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                const Text(
                  'Chọn ví',
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
                          name: 'Tất cả ví',
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
                child: const Text(
                  'Chính',
                  style: TextStyle(
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

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMonthButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _changeMonth(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM, yyyy', 'vi').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildMonthButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
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

        // Total balance across all time for selected wallet
        final allExpenses = walletProvider.filterByWallet(
          expenseProvider.expenses,
        );
        final totalBalanceAllTime =
            allExpenses
                .where((e) => e.type == ExpenseType.income)
                .fold(0.0, (sum, e) => sum + e.amount) -
            allExpenses
                .where((e) => e.type == ExpenseType.expense)
                .fold(0.0, (sum, e) => sum + e.amount);

        return Column(
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: balance >= 0
                      ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                      : [const Color(0xFFEF4444), const Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (balance >= 0 ? AppColors.primary : AppColors.error)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Số dư tháng này',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBalanceVisible = !_isBalanceVisible;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isBalanceVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 38,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previousChildren, ?currentChild],
                        );
                      },
                      child: _isBalanceVisible
                          ? Text(
                              currencyFormat.format(balance),
                              key: const ValueKey('visible'),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                                height: 1.1,
                              ),
                            )
                          : const Text(
                              '••••••••',
                              key: ValueKey('hidden'),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                                height: 1.1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expenses.length} giao dịch trong tháng',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng số dư',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _isBalanceVisible
                              ? currencyFormat.format(totalBalanceAllTime)
                              : '••••••',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Income & Expense Cards
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    title: 'Thu nhập',
                    amount: totalIncome,
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMiniStatCard(
                    title: 'Chi tiêu',
                    amount: totalExpense,
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('all', 'Tất cả', Icons.list_rounded),
        const SizedBox(width: 10),
        _buildFilterChip('income', 'Thu nhập', Icons.arrow_downward_rounded),
        const SizedBox(width: 10),
        _buildFilterChip('expense', 'Chi tiêu', Icons.arrow_upward_rounded),
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
                  ? const LinearGradient(colors: AppColors.primaryGradient)
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
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
                  style: TextStyle(
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
                color: Colors.white,
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
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thêm giao dịch đầu tiên của bạn',
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
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
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
                                style: const TextStyle(
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
                                style: const TextStyle(
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
                ? const Border(
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
                            style: const TextStyle(
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
                            child: const Text(
                              'Tự động',
                              style: TextStyle(
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
                        style: const TextStyle(
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
                                style: const TextStyle(
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFilterDialogOption(
                  'all',
                  'Tất cả giao dịch',
                  Icons.list_rounded,
                ),
                _buildFilterDialogOption(
                  'income',
                  'Chỉ thu nhập',
                  Icons.arrow_downward_rounded,
                ),
                _buildFilterDialogOption(
                  'expense',
                  'Chỉ chi tiêu',
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
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

    if (dateOnly == today) return 'Hôm nay';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hôm qua';

    return DateFormat('EEEE', 'vi').format(date);
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
