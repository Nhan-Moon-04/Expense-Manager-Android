import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/admin_colors.dart';
import '../../constants/admin_strings.dart';
import '../../providers/admin_stats_provider.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStatsProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminStatsProvider>(
      builder: (context, stats, _) {
        if (stats.isLoading && stats.totalUsers == 0) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => stats.loadDashboardStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  AdminStrings.dashboard,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng quan hệ thống - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Stat cards row 1
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1000
                        ? 4
                        : constraints.maxWidth > 600
                        ? 2
                        : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        StatCard(
                          title: AdminStrings.totalUsers,
                          value: '${stats.totalUsers}',
                          icon: Icons.people_rounded,
                          color: AdminColors.accent,
                          subtitle: '${stats.activeUsers} đang hoạt động',
                        ),
                        StatCard(
                          title: AdminStrings.newUsersToday,
                          value: '${stats.newUsersToday}',
                          icon: Icons.person_add_rounded,
                          color: AdminColors.success,
                          subtitle:
                              '${stats.newUsersThisMonth} trong tháng này',
                        ),
                        StatCard(
                          title: AdminStrings.totalGroups,
                          value: '${stats.totalGroups}',
                          icon: Icons.group_work_rounded,
                          color: AdminColors.info,
                        ),
                        StatCard(
                          title: 'Tổng Giao Dịch',
                          value: '${stats.totalExpenses}',
                          icon: Icons.receipt_long_rounded,
                          color: AdminColors.warning,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Income/Expense summary
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.0,
                      children: [
                        StatCard(
                          title: 'Thu Nhập Tháng Này',
                          value: _currencyFormat.format(
                            stats.overallIncomeExpense['income'] ?? 0,
                          ),
                          icon: Icons.trending_up_rounded,
                          color: AdminColors.incomeColor,
                        ),
                        StatCard(
                          title: 'Chi Tiêu Tháng Này',
                          value: _currencyFormat.format(
                            stats.overallIncomeExpense['expense'] ?? 0,
                          ),
                          icon: Icons.trending_down_rounded,
                          color: AdminColors.expenseColor,
                        ),
                        StatCard(
                          title: 'Chênh Lệch',
                          value: _currencyFormat.format(
                            stats.overallIncomeExpense['balance'] ?? 0,
                          ),
                          icon: Icons.account_balance_wallet_rounded,
                          color:
                              (stats.overallIncomeExpense['balance'] ?? 0) >= 0
                              ? AdminColors.success
                              : AdminColors.error,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông Tin Nhanh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Tỷ lệ users hoạt động',
                        stats.totalUsers > 0
                            ? '${((stats.activeUsers / stats.totalUsers) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        AdminColors.success,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Tổng users không hoạt động',
                        '${stats.totalUsers - stats.activeUsers}',
                        AdminColors.error,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Trung bình giao dịch/user',
                        stats.totalUsers > 0
                            ? (stats.totalExpenses / stats.totalUsers)
                                  .toStringAsFixed(1)
                            : '0',
                        AdminColors.info,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
