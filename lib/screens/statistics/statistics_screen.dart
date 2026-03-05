import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/expense_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedMonthOffset = 0; // 0 = this month, -1 = last month, etc.

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.statistics,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<ExpenseProvider, SettingsProvider>(
        builder: (context, expenseProvider, settingsProvider, _) {
          final currencyFormat = settingsProvider.currencyFormat;
          final expenses = expenseProvider.expenses;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noStatisticsData,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter expenses by selected month
          final now = DateTime.now();
          final selectedMonth = DateTime(
            now.year,
            now.month + _selectedMonthOffset,
          );
          final monthStart = DateTime(
            selectedMonth.year,
            selectedMonth.month,
            1,
          );
          final monthEnd = DateTime(
            selectedMonth.year,
            selectedMonth.month + 1,
            0,
            23,
            59,
            59,
          );

          final monthExpenses = expenses.where((e) {
            return e.date.isAfter(
                  monthStart.subtract(const Duration(seconds: 1)),
                ) &&
                e.date.isBefore(monthEnd.add(const Duration(seconds: 1)));
          }).toList();

          final totalIncome = monthExpenses
              .where((e) => e.type == ExpenseType.income)
              .fold(0.0, (sum, e) => sum + e.amount);
          final totalExpense = monthExpenses
              .where((e) => e.type == ExpenseType.expense)
              .fold(0.0, (sum, e) => sum + e.amount);
          final netBalance = totalIncome - totalExpense;

          // Category breakdown (expenses only)
          final Map<ExpenseCategory, double> categoryMap = {};
          for (final e in monthExpenses.where(
            (e) => e.type == ExpenseType.expense,
          )) {
            categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
          }
          final sortedCategories = categoryMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Daily summary
          final Map<int, double> dailyExpense = {};
          final Map<int, double> dailyIncome = {};
          for (final e in monthExpenses) {
            if (e.type == ExpenseType.expense) {
              dailyExpense[e.date.day] =
                  (dailyExpense[e.date.day] ?? 0) + e.amount;
            } else {
              dailyIncome[e.date.day] =
                  (dailyIncome[e.date.day] ?? 0) + e.amount;
            }
          }

          // Transaction count
          final expenseCount = monthExpenses
              .where((e) => e.type == ExpenseType.expense)
              .length;
          final incomeCount = monthExpenses
              .where((e) => e.type == ExpenseType.income)
              .length;

          // Average daily expense
          final daysInMonth = monthEnd.day;
          final daysPassed = _selectedMonthOffset == 0 ? now.day : daysInMonth;
          final avgDailyExpense = daysPassed > 0
              ? totalExpense / daysPassed
              : 0.0;

          // Top spending day
          int? topDay;
          double topDayAmount = 0;
          dailyExpense.forEach((day, amount) {
            if (amount > topDayAmount) {
              topDay = day;
              topDayAmount = amount;
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selector
                _buildMonthSelector(selectedMonth, isDark),
                const SizedBox(height: 20),

                // Overview cards
                _buildOverviewCards(
                  totalIncome,
                  totalExpense,
                  netBalance,
                  currencyFormat,
                  isDark,
                ),
                const SizedBox(height: 24),

                // Quick stats
                _buildQuickStats(
                  expenseCount,
                  incomeCount,
                  avgDailyExpense,
                  topDay,
                  topDayAmount,
                  selectedMonth,
                  currencyFormat,
                  isDark,
                ),
                const SizedBox(height: 24),

                // Income vs Expense bar
                _buildIncomeVsExpenseBar(totalIncome, totalExpense, isDark),
                const SizedBox(height: 24),

                // Category breakdown
                if (sortedCategories.isNotEmpty) ...[
                  _buildSectionTitle(AppStrings.categoryBreakdown, isDark),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(
                    sortedCategories,
                    totalExpense,
                    currencyFormat,
                    isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                // Daily chart (simple bar representation)
                _buildSectionTitle(AppStrings.dailyExpense, isDark),
                const SizedBox(height: 12),
                _buildDailyChart(dailyExpense, daysInMonth, isDark),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(DateTime selectedMonth, bool isDark) {
    final monthLabel = DateFormat('MMMM yyyy', AppLocalizations.currentLanguage).format(selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() => _selectedMonthOffset--);
            },
          ),
          Text(
            monthLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _selectedMonthOffset >= 0
                  ? (isDark ? Colors.white24 : AppColors.textHint)
                  : (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
            onPressed: _selectedMonthOffset >= 0
                ? null
                : () {
                    setState(() => _selectedMonthOffset++);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(
    double income,
    double expense,
    double net,
    NumberFormat fmt,
    bool isDark,
  ) {
    return Column(
      children: [
        // Net balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: net >= 0
                  ? [const Color(0xFF22C55E), const Color(0xFF14B8A6)]
                  : [const Color(0xFFEF4444), const Color(0xFFF97316)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    (net >= 0 ? AppColors.incomeColor : AppColors.expenseColor)
                        .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.monthlyBalanceStat,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fmt.format(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Income / Expense row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppStrings.income,
                fmt.format(income),
                Icons.arrow_downward_rounded,
                AppColors.incomeColor,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppStrings.expense,
                fmt.format(expense),
                Icons.arrow_upward_rounded,
                AppColors.expenseColor,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    int expenseCount,
    int incomeCount,
    double avgDaily,
    int? topDay,
    double topDayAmount,
    DateTime selectedMonth,
    NumberFormat fmt,
    bool isDark,
  ) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
          _buildStatRow(
            AppStrings.expenseTransactionCount,
            '$expenseCount ${AppStrings.transactionsSuffix}',
            Icons.receipt_long_rounded,
            AppColors.expenseColor,
            textColor,
            subColor,
          ),
          const Divider(height: 20),
          _buildStatRow(
            AppStrings.incomeTransactionCount,
            '$incomeCount ${AppStrings.transactionsSuffix}',
            Icons.receipt_rounded,
            AppColors.incomeColor,
            textColor,
            subColor,
          ),
          const Divider(height: 20),
          _buildStatRow(
            AppStrings.avgDailyExpense,
            fmt.format(avgDaily),
            Icons.speed_rounded,
            AppColors.info,
            textColor,
            subColor,
          ),
          if (topDay != null) ...[
            const Divider(height: 20),
            _buildStatRow(
              AppStrings.topSpendingDay,
              '$topDay/${selectedMonth.month} - ${fmt.format(topDayAmount)}',
              Icons.trending_up_rounded,
              AppColors.warning,
              textColor,
              subColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: subColor, fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeVsExpenseBar(double income, double expense, bool isDark) {
    final total = income + expense;
    if (total == 0) return const SizedBox.shrink();

    final incomeRatio = income / total;
    final expenseRatio = expense / total;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.incomeVsExpense,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (incomeRatio > 0)
                    Expanded(
                      flex: (incomeRatio * 100).round(),
                      child: Container(
                        color: AppColors.incomeColor,
                        alignment: Alignment.center,
                        child: incomeRatio > 0.15
                            ? Text(
                                '${(incomeRatio * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  if (expenseRatio > 0)
                    Expanded(
                      flex: (expenseRatio * 100).round(),
                      child: Container(
                        color: AppColors.expenseColor,
                        alignment: Alignment.center,
                        child: expenseRatio > 0.15
                            ? Text(
                                '${(expenseRatio * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(AppStrings.income, AppColors.incomeColor),
              const SizedBox(width: 20),
              _buildLegendItem(AppStrings.expense, AppColors.expenseColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    List<MapEntry<ExpenseCategory, double>> categories,
    double totalExpense,
    NumberFormat fmt,
    bool isDark,
  ) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: categories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percent = totalExpense > 0 ? (amount / totalExpense) : 0.0;
          final color = _getCategoryColor(category);
          final icon = _getCategoryIcon(category);
          final name = _getCategoryName(category);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmt.format(amount),
                            style: TextStyle(color: subColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyChart(
    Map<int, double> dailyExpense,
    int daysInMonth,
    bool isDark,
  ) {
    if (dailyExpense.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            AppStrings.noExpenseThisMonth,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final maxAmount = dailyExpense.values.fold(
      0.0,
      (max, v) => v > max ? v : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(daysInMonth, (index) {
            final day = index + 1;
            final amount = dailyExpense[day] ?? 0;
            final ratio = maxAmount > 0 ? amount / maxAmount : 0.0;

            return Expanded(
              child: Tooltip(
                message: '${AppStrings.dayPrefix} $day: ${amount.toStringAsFixed(0)}đ',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: ratio > 0 ? ratio.clamp(0.05, 1.0) : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: amount > 0
                                  ? AppColors.expenseColor.withValues(
                                      alpha: 0.3 + (ratio * 0.7),
                                    )
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (day % 5 == 0 || day == 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 8,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textHint,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
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
        return AppColors.success;
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
        return Icons.local_hospital_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.salary:
        return Icons.work_rounded;
      case ExpenseCategory.bonus:
        return Icons.card_giftcard_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return AppStrings.food;
      case ExpenseCategory.transport:
        return AppStrings.transport;
      case ExpenseCategory.shopping:
        return AppStrings.shopping;
      case ExpenseCategory.entertainment:
        return AppStrings.entertainment;
      case ExpenseCategory.bills:
        return AppStrings.bills;
      case ExpenseCategory.health:
        return AppStrings.health;
      case ExpenseCategory.education:
        return AppStrings.education;
      case ExpenseCategory.salary:
        return AppStrings.salary;
      case ExpenseCategory.bonus:
        return AppStrings.bonus;
      case ExpenseCategory.other:
        return AppStrings.other;
    }
  }
}
