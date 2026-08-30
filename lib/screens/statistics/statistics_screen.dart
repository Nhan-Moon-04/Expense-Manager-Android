import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../expenses/expense_detail_screen.dart';
import 'widgets/financial_insight_card.dart';

enum StatisticsPeriod { week, month, quarter, year, all }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod _selectedPeriod = StatisticsPeriod.month;
  int _selectedMonthOffset = 0; // 0 = this month, -1 = last month
  int _touchedPieIndex = -1;

  // Curated category colors for charts
  final List<Color> _chartColors = const [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF64748B), // Slate
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  DateTime _getSelectedMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthOffset);
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> allExpenses) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case StatisticsPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return allExpenses.where((e) => e.date.isAfter(startOfDay.subtract(const Duration(seconds: 1)))).toList();

      case StatisticsPeriod.month:
        final targetMonth = _getSelectedMonth();
        final start = DateTime(targetMonth.year, targetMonth.month, 1);
        final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);
        return allExpenses.where((e) => e.date.isAfter(start.subtract(const Duration(seconds: 1))) && e.date.isBefore(end.add(const Duration(seconds: 1)))).toList();

      case StatisticsPeriod.quarter:
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return allExpenses.where((e) => e.date.isAfter(quarterStart.subtract(const Duration(seconds: 1)))).toList();

      case StatisticsPeriod.year:
        final yearStart = DateTime(now.year, 1, 1);
        return allExpenses.where((e) => e.date.isAfter(yearStart.subtract(const Duration(seconds: 1)))).toList();

      case StatisticsPeriod.all:
        return allExpenses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;
    final allExpenses = context.watch<ExpenseProvider>().expenses;
    final periodExpenses = _filterExpenses(allExpenses);

    final totalIncome = periodExpenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalExpense = periodExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    final netBalance = totalIncome - totalExpense;

    // Category breakdown
    final Map<ExpenseCategory, double> categoryAmounts = {};
    for (final exp in periodExpenses.where((e) => e.type == ExpenseType.expense)) {
      categoryAmounts[exp.category] = (categoryAmounts[exp.category] ?? 0.0) + exp.amount;
    }

    final sortedCategories = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 5 highest expenses
    final topExpenses = periodExpenses
        .where((e) => e.type == ExpenseType.expense)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topExpenses.take(5).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'Thống Kê & Phân Tích',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Period Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildPeriodChip(StatisticsPeriod.week, 'Tuần này'),
                            _buildPeriodChip(StatisticsPeriod.month, 'Tháng này'),
                            _buildPeriodChip(StatisticsPeriod.quarter, 'Quý này'),
                            _buildPeriodChip(StatisticsPeriod.year, 'Năm nay'),
                            _buildPeriodChip(StatisticsPeriod.all, 'Tất cả'),
                          ],
                        ),
                      ),
                      if (_selectedPeriod == StatisticsPeriod.month) ...[
                        const SizedBox(height: 12),
                        _buildMonthNavigator(),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Summary Hero Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSummaryOverview(
                    totalIncome,
                    totalExpense,
                    netBalance,
                    currencyFormat,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Financial Health & Insights Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FinancialInsightCard(
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    expenses: periodExpenses,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Donut Chart: Phân bổ danh mục chi tiêu
              if (sortedCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCategoryPieChartSection(
                      sortedCategories,
                      totalExpense,
                      currencyFormat,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Category Breakdown List
              if (sortedCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Chi Tiết Theo Danh Mục',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = sortedCategories[index];
                        final category = entry.key;
                        final amount = entry.value;
                        final percent = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
                        final color = _chartColors[index % _chartColors.length];

                        return _buildCategoryRow(
                          category,
                          amount,
                          percent,
                          color,
                          currencyFormat,
                        );
                      },
                      childCount: sortedCategories.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Top 5 Largest Expenses
              if (top5.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Top 5 Khoản Chi Lớn Nhất',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = top5[index];
                        return _buildTopExpenseRow(expense, currencyFormat);
                      },
                      childCount: top5.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(StatisticsPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderColor),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedPeriod = period;
            });
          }
        },
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final targetMonth = _getSelectedMonth();
    final monthStr = DateFormat('MM/yyyy').format(targetMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _selectedMonthOffset--),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Tháng $monthStr',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _selectedMonthOffset < 0
                ? () => setState(() => _selectedMonthOffset++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryOverview(
    double income,
    double expense,
    double net,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số Dư Ròng (Thu - Chi)',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            format.format(net),
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 14),
                          const SizedBox(width: 4),
                          Text('Tổng Thu', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        format.format(income),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 14),
                          const SizedBox(width: 4),
                          Text('Tổng Chi', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        format.format(expense),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildCategoryPieChartSection(
    List<MapEntry<ExpenseCategory, double>> sortedCategories,
    double totalExpense,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phân Bổ Chi Tiêu',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${sortedCategories.length} danh mục',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 46,
                sections: List.generate(sortedCategories.length, (i) {
                  final isTouched = i == _touchedPieIndex;
                  final fontSize = isTouched ? 14.0 : 11.0;
                  final radius = isTouched ? 48.0 : 42.0;
                  final entry = sortedCategories[i];
                  final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                  final color = _chartColors[i % _chartColors.length];

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: radius,
                    titleStyle: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    ExpenseCategory category,
    double amount,
    double percent,
    Color color,
    NumberFormat format,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ExpenseModel.getCategoryName(category),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                format.format(amount),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpenseRow(ExpenseModel expense, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.expenseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expenseColor, size: 20),
        ),
        title: Text(
          expense.displayName,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('HH:mm - dd/MM/yyyy').format(expense.date),
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Text(
          '-${format.format(expense.amount)}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.expenseColor,
          ),
        ),
      ),
    ),
  );
}
}
