import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../models/expense_model.dart';

class FinancialInsightCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final List<ExpenseModel> expenses;
  final NumberFormat currencyFormat;

  const FinancialInsightCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenses,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Savings Rate Calculation
    final double netSavings = totalIncome - totalExpense;
    final double savingsRate = totalIncome > 0
        ? (netSavings / totalIncome) * 100
        : 0.0;

    // 2. Average Daily Spending (Calculated over 30 days or days in current month)
    final now = DateTime.now();
    final daysElapsed = now.day > 0 ? now.day : 1;
    final double avgDailySpend = totalExpense / daysElapsed;
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final double projectedMonthExpense = avgDailySpend * daysInMonth;

    // 3. Health status
    String healthStatus;
    Color healthColor;
    IconData healthIcon;

    if (totalIncome == 0 && totalExpense == 0) {
      healthStatus = 'Chưa có dữ liệu';
      healthColor = AppColors.textSecondary;
      healthIcon = Icons.info_outline_rounded;
    } else if (savingsRate >= 30) {
      healthStatus = 'Rất Tốt (Xuất sắc)';
      healthColor = const Color(0xFF10B981);
      healthIcon = Icons.verified_rounded;
    } else if (savingsRate >= 15) {
      healthStatus = 'Ổn Định (An toàn)';
      healthColor = const Color(0xFF3B82F6);
      healthIcon = Icons.thumb_up_rounded;
    } else if (savingsRate >= 0) {
      healthStatus = 'Cần Tiết Kiệm Thêm';
      healthColor = const Color(0xFFF59E0B);
      healthIcon = Icons.warning_amber_rounded;
    } else {
      healthStatus = 'Bội Chi (Nguy hiểm)';
      healthColor = const Color(0xFFEF4444);
      healthIcon = Icons.error_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Responsive Overflow-Free)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(healthIcon, color: healthColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sức Khỏe Tài Chính',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: healthColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  healthStatus,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Savings Rate Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ tích lũy / tiết kiệm',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: healthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: savingsRate > 0
                  ? (savingsRate / 100).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Metric Columns: Daily Avg & Month Projection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiêu TB / ngày',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(avgDailySpend),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.dividerColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dự báo cả tháng',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(projectedMonthExpense),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
