import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/admin_colors.dart';
import '../../constants/admin_strings.dart';
import '../../providers/admin_stats_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTabData();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadCurrentTabData();
  }

  void _loadCurrentTabData() {
    final stats = context.read<AdminStatsProvider>();
    switch (_tabController.index) {
      case 0:
        stats.loadDailyStats(_selectedYear, _selectedMonth);
        break;
      case 1:
        stats.loadMonthlyStats(_selectedYear);
        break;
      case 2:
        stats.loadYearlyStats();
        break;
      case 3:
        DateTime start = DateTime(_selectedYear, _selectedMonth, 1);
        DateTime end = DateTime(
          _selectedYear,
          _selectedMonth + 1,
          0,
          23,
          59,
          59,
        );
        stats.loadCategoryStats(start, end);
        stats.loadTopSpenders(startDate: start, endDate: end);
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AdminStrings.statistics,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Date selectors
              Row(
                children: [
                  // Year selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        items: List.generate(5, (i) => DateTime.now().year - i)
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('Năm $year'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedYear = value!);
                          _loadCurrentTabData();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Month selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text('Tháng $month'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedMonth = value!);
                          _loadCurrentTabData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AdminColors.accent,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.accent,
                  tabs: const [
                    Tab(text: 'Theo Ngày'),
                    Tab(text: 'Theo Tháng'),
                    Tab(text: 'Theo Năm'),
                    Tab(text: 'Chi Tiết'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDailyTab(),
              _buildMonthlyTab(),
              _buildYearlyTab(),
              _buildDetailTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DAILY TAB ====================
  Widget _buildDailyTab() {
    return Consumer<AdminStatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.dailyStats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final dailyStats = stats.dailyStats;
        int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

        // Tính tổng
        double totalIncome = 0, totalExpense = 0;
        for (var entry in dailyStats.values) {
          totalIncome += entry['income'] ?? 0;
          totalExpense += entry['expense'] ?? 0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Thu nhập',
                      totalIncome,
                      AdminColors.incomeColor,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Chi tiêu',
                      totalExpense,
                      AdminColors.expenseColor,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Chart
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: dailyStats.isEmpty
                    ? const Center(child: Text('Không có dữ liệu'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(dailyStats),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                String label = rodIndex == 0 ? 'Thu' : 'Chi';
                                return BarTooltipItem(
                                  'Ngày ${group.x + 1}\n$label: ${_currencyFormat.format(rod.toY)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int day = value.toInt() + 1;
                                  if (day % 5 == 0 || day == 1) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '$day',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatShortCurrency(value),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          barGroups: List.generate(daysInMonth, (i) {
                            int day = i + 1;
                            double income = dailyStats[day]?['income'] ?? 0;
                            double expense = dailyStats[day]?['expense'] ?? 0;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: income,
                                  color: AdminColors.incomeColor,
                                  width: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                BarChartRodData(
                                  toY: expense,
                                  color: AdminColors.expenseColor,
                                  width: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chi tiết theo ngày',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Ngày')),
                          DataColumn(label: Text('Thu nhập')),
                          DataColumn(label: Text('Chi tiêu')),
                          DataColumn(label: Text('Chênh lệch')),
                        ],
                        rows: List.generate(daysInMonth, (i) {
                          int day = i + 1;
                          double income = dailyStats[day]?['income'] ?? 0;
                          double expense = dailyStats[day]?['expense'] ?? 0;
                          double diff = income - expense;
                          if (income == 0 && expense == 0) return null;
                          return DataRow(
                            cells: [
                              DataCell(Text('$day/$_selectedMonth')),
                              DataCell(
                                Text(
                                  _currencyFormat.format(income),
                                  style: const TextStyle(
                                    color: AdminColors.incomeColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(expense),
                                  style: const TextStyle(
                                    color: AdminColors.expenseColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(diff),
                                  style: TextStyle(
                                    color: diff >= 0
                                        ? AdminColors.success
                                        : AdminColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).whereType<DataRow>().toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==================== MONTHLY TAB ====================
  Widget _buildMonthlyTab() {
    return Consumer<AdminStatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.monthlyStats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final monthlyStats = stats.monthlyStats;
        double totalIncome = 0, totalExpense = 0;
        for (var entry in monthlyStats.values) {
          totalIncome += entry['income'] ?? 0;
          totalExpense += entry['expense'] ?? 0;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Tổng thu cả năm',
                      totalIncome,
                      AdminColors.incomeColor,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Tổng chi cả năm',
                      totalExpense,
                      AdminColors.expenseColor,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Chart
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxYMonthly(monthlyStats),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String label = rodIndex == 0 ? 'Thu' : 'Chi';
                          return BarTooltipItem(
                            'T${group.x + 1}\n$label: ${_currencyFormat.format(rod.toY)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'T${value.toInt() + 1}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatShortCurrency(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    barGroups: List.generate(12, (i) {
                      int month = i + 1;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthlyStats[month]?['income'] ?? 0,
                            color: AdminColors.incomeColor,
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: monthlyStats[month]?['expense'] ?? 0,
                            color: AdminColors.expenseColor,
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chi tiết theo tháng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tháng')),
                          DataColumn(label: Text('Thu nhập')),
                          DataColumn(label: Text('Chi tiêu')),
                          DataColumn(label: Text('Chênh lệch')),
                        ],
                        rows: List.generate(12, (i) {
                          int month = i + 1;
                          double income = monthlyStats[month]?['income'] ?? 0;
                          double expense = monthlyStats[month]?['expense'] ?? 0;
                          double diff = income - expense;
                          return DataRow(
                            cells: [
                              DataCell(Text('Tháng $month')),
                              DataCell(
                                Text(
                                  _currencyFormat.format(income),
                                  style: const TextStyle(
                                    color: AdminColors.incomeColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(expense),
                                  style: const TextStyle(
                                    color: AdminColors.expenseColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(diff),
                                  style: TextStyle(
                                    color: diff >= 0
                                        ? AdminColors.success
                                        : AdminColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==================== YEARLY TAB ====================
  Widget _buildYearlyTab() {
    return Consumer<AdminStatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.yearlyStats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final yearlyStats = stats.yearlyStats;
        if (yearlyStats.isEmpty) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        var sortedYears = yearlyStats.keys.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Chart
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxYMonthly(yearlyStats),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int idx = value.toInt();
                            if (idx >= 0 && idx < sortedYears.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${sortedYears[idx]}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatShortCurrency(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    barGroups: List.generate(sortedYears.length, (i) {
                      int year = sortedYears[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: yearlyStats[year]?['income'] ?? 0,
                            color: AdminColors.incomeColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: yearlyStats[year]?['expense'] ?? 0,
                            color: AdminColors.expenseColor,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Chi tiết theo năm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Năm')),
                          DataColumn(label: Text('Thu nhập')),
                          DataColumn(label: Text('Chi tiêu')),
                          DataColumn(label: Text('Chênh lệch')),
                        ],
                        rows: sortedYears.map((year) {
                          double income = yearlyStats[year]?['income'] ?? 0;
                          double expense = yearlyStats[year]?['expense'] ?? 0;
                          double diff = income - expense;
                          return DataRow(
                            cells: [
                              DataCell(Text('$year')),
                              DataCell(
                                Text(
                                  _currencyFormat.format(income),
                                  style: const TextStyle(
                                    color: AdminColors.incomeColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(expense),
                                  style: const TextStyle(
                                    color: AdminColors.expenseColor,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currencyFormat.format(diff),
                                  style: TextStyle(
                                    color: diff >= 0
                                        ? AdminColors.success
                                        : AdminColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ==================== DETAIL TAB ====================
  Widget _buildDetailTab() {
    return Consumer<AdminStatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading &&
            stats.categoryStats.isEmpty &&
            stats.topSpenders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoryStats = stats.categoryStats;
        final topSpenders = stats.topSpenders;
        double totalCategory = categoryStats.values.fold(0, (a, b) => a + b);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Pie Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AdminStrings.categoryStats} (T$_selectedMonth/$_selectedYear)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categoryStats.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Không có dữ liệu chi tiêu'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Pie chart
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieSections(
                                  categoryStats,
                                  totalCategory,
                                ),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Legend
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryStats.entries.map((entry) {
                                int colorIdx = categoryStats.keys
                                    .toList()
                                    .indexOf(entry.key);
                                double pct = totalCategory > 0
                                    ? (entry.value / totalCategory) * 100
                                    : 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color:
                                              AdminColors.chartColors[colorIdx %
                                                  AdminColors
                                                      .chartColors
                                                      .length],
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AdminStrings.categoryNames[entry
                                                  .key] ??
                                              entry.key,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '${pct.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category table
              if (categoryStats.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Chi tiết danh mục',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Danh mục')),
                            DataColumn(label: Text('Số tiền')),
                            DataColumn(label: Text('Tỷ lệ')),
                          ],
                          rows: categoryStats.entries.map((entry) {
                            double pct = totalCategory > 0
                                ? (entry.value / totalCategory) * 100
                                : 0;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    AdminStrings.categoryNames[entry.key] ??
                                        entry.key,
                                  ),
                                ),
                                DataCell(
                                  Text(_currencyFormat.format(entry.value)),
                                ),
                                DataCell(Text('${pct.toStringAsFixed(1)}%')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Top Spenders
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AdminStrings.topSpenders,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (topSpenders.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Không có dữ liệu'),
                        ),
                      )
                    else
                      ...topSpenders.asMap().entries.map((entry) {
                        int rank = entry.key + 1;
                        var data = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rank <= 3
                                ? [
                                    Colors.amber,
                                    Colors.grey.shade400,
                                    Colors.brown.shade300,
                                  ][rank - 1]
                                : AdminColors.accent.withValues(alpha: 0.1),
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: rank <= 3
                                    ? Colors.white
                                    : AdminColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            data['userName'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            _currencyFormat.format(data['totalExpense']),
                            style: const TextStyle(
                              color: AdminColors.expenseColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ========== Helpers ==========

  Widget _summaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> data,
    double total,
  ) {
    return data.entries.map((entry) {
      int idx = data.keys.toList().indexOf(entry.key);
      double pct = total > 0 ? (entry.value / total) * 100 : 0;
      return PieChartSectionData(
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: AdminColors.chartColors[idx % AdminColors.chartColors.length],
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  double _getMaxY(Map<int, Map<String, double>> data) {
    double max = 0;
    for (var entry in data.values) {
      double income = entry['income'] ?? 0;
      double expense = entry['expense'] ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max * 1.2;
  }

  double _getMaxYMonthly(Map<int, Map<String, double>> data) {
    double max = 0;
    for (var entry in data.values) {
      double income = entry['income'] ?? 0;
      double expense = entry['expense'] ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max * 1.2;
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}tr';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
