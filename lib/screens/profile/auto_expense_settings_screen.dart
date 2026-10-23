import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../providers/auto_expense_provider.dart';

/// Phase 2.3 – Dedicated Auto Expense Settings Screen
/// Handles notification listening configuration, bank selections,
/// permission granting, mode selection, and recent parsed transaction logs.
class AutoExpenseSettingsScreen extends StatefulWidget {
  const AutoExpenseSettingsScreen({super.key});

  @override
  State<AutoExpenseSettingsScreen> createState() =>
      _AutoExpenseSettingsScreenState();
}

class _AutoExpenseSettingsScreenState extends State<AutoExpenseSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _logTabController;
  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  final List<Map<String, dynamic>> _supportedBanks = [
    {
      'source': 'momo',
      'name': 'Ví MoMo',
      'category': 'ewallet',
      'color': const Color(0xFFA50064),
      'initials': 'MoMo',
    },
    {
      'source': 'zalopay',
      'name': 'ZaloPay',
      'category': 'ewallet',
      'color': const Color(0xFF0068FF),
      'initials': 'ZP',
    },
    {
      'source': 'vcb',
      'name': 'Vietcombank',
      'category': 'bank',
      'color': const Color(0xFF005A36),
      'initials': 'VCB',
    },
    {
      'source': 'mbbank',
      'name': 'MB Bank',
      'category': 'bank',
      'color': const Color(0xFF1B365D),
      'initials': 'MB',
    },
    {
      'source': 'techcombank',
      'name': 'Techcombank',
      'category': 'bank',
      'color': const Color(0xFFE41E26),
      'initials': 'TCB',
    },
    {
      'source': 'vpbank',
      'name': 'VPBank',
      'category': 'bank',
      'color': const Color(0xFF009156),
      'initials': 'VPB',
    },
    {
      'source': 'bidv',
      'name': 'BIDV',
      'category': 'bank',
      'color': const Color(0xFF025A55),
      'initials': 'BIDV',
    },
    {
      'source': 'tpbank',
      'name': 'TPBank',
      'category': 'bank',
      'color': const Color(0xFF7B2D85),
      'initials': 'TPB',
    },
    {
      'source': 'vietinbank',
      'name': 'VietinBank',
      'category': 'bank',
      'color': const Color(0xFF004B87),
      'initials': 'CTG',
    },
    {
      'source': 'acb',
      'name': 'ACB',
      'category': 'bank',
      'color': const Color(0xFF0A4D9A),
      'initials': 'ACB',
    },
    {
      'source': 'sacombank',
      'name': 'Sacombank',
      'category': 'bank',
      'color': const Color(0xFF005DAA),
      'initials': 'STB',
    },
    {
      'source': 'agribank',
      'name': 'Agribank',
      'category': 'bank',
      'color': const Color(0xFF8B1D2C),
      'initials': 'VBA',
    },
  ];

  @override
  void initState() {
    super.initState();
    _logTabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AutoExpenseProvider>().checkNotificationAccess();
      }
    });
  }

  @override
  void dispose() {
    _logTabController.dispose();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Tự động ghi nhận là gì?', style: AppTypography.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khi ứng dụng ngân hàng hoặc ví điện tử gửi thông báo biến động số dư, hệ thống sẽ tự động bóc tách số tiền, nội dung và nguồn tiền để tạo giao dịch.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bảo mật 100%: Xử lý hoàn toàn offline trên điện thoại. Không đọc mã OTP hay mật khẩu.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoExpenseProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Tự động ghi nhận',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded, size: 22),
                onPressed: _showHelpDialog,
                tooltip: 'Trợ giúp',
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. HERO MASTER TOGGLE CARD ───
                _buildMasterToggleCard(provider),

                const SizedBox(height: 16),

                // ─── 2. PERMISSION STATUS CARD ───
                _buildPermissionStatusCard(provider),

                const SizedBox(height: 20),

                // ─── 3. MODE & TRACKING RULES ───
                _buildSectionTitle('Quy tắc nhận diện', Icons.tune_rounded),
                const SizedBox(height: 10),
                _buildRulesCard(provider),

                const SizedBox(height: 24),

                // ─── 4. SUPPORTED BANKS & EWALLETS ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Ngân hàng & Ví hỗ trợ', Icons.account_balance_rounded),
                    TextButton(
                      onPressed: () {
                        final allActive = _supportedBanks
                            .every((b) => provider.isBankEnabled(b['source']!));
                        for (final b in _supportedBanks) {
                          provider.setBankEnabled(b['source']!, !allActive);
                        }
                      },
                      child: Text(
                        _supportedBanks.every((b) => provider.isBankEnabled(b['source']!))
                            ? 'Tắt tất cả'
                            : 'Bật tất cả',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildBanksGrid(provider),

                const SizedBox(height: 24),

                // ─── 5. NOTIFICATION LOGS & PENDING ───
                _buildSectionTitle('Lịch sử nhận diện', Icons.receipt_long_rounded),
                const SizedBox(height: 10),
                _buildLogsCard(provider),

                const SizedBox(height: 20),

                // ─── 6. SECURITY & PRIVACY FOOTNOTE ───
                _buildSecurityCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.h3.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── 1. HERO MASTER TOGGLE CARD ───
  Widget _buildMasterToggleCard(AutoExpenseProvider provider) {
    final isEnabled = provider.isEnabled;

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isEnabled ? Colors.transparent : AppColors.dividerColor,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppShadows.card,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: isEnabled ? Colors.white : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đọc thông báo tự động',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Đang lắng nghe biến động từ ngân hàng & ví điện tử'
                      : 'Bật để tự ghi sổ khi nhận tin nhắn trừ / cộng tiền',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isEnabled
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (val) => provider.setEnabled(val),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  // ─── 2. PERMISSION STATUS CARD ───
  Widget _buildPermissionStatusCard(AutoExpenseProvider provider) {
    final granted = provider.isNotificationAccessGranted;

    if (granted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quyền truy cập thông báo: Đã sẵn sàng hoạt động',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cần cấp quyền truy cập thông báo',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ điều hành Android yêu cầu cấp quyền để ứng dụng đọc được nội dung biến động số dư từ thanh trạng thái.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.requestNotificationAccess(),
              icon: const Icon(Icons.security_update_good_rounded, size: 18),
              label: const Text('Cấp quyền trong Cài đặt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. RULES CARD ───
  Widget _buildRulesCard(AutoExpenseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _buildToggleTile(
            icon: Icons.north_east_rounded,
            iconColor: AppColors.expenseColor,
            title: 'Tự động tạo Chi tiêu',
            subtitle: 'Ghi nhận các giao dịch trừ tiền từ tài khoản',
            value: provider.autoAddExpense,
            onChanged: (val) => provider.setAutoAddExpense(val),
          ),
          const Divider(height: 1, indent: 56),
          _buildToggleTile(
            icon: Icons.south_west_rounded,
            iconColor: AppColors.incomeColor,
            title: 'Tự động tạo Thu nhập',
            subtitle: 'Ghi nhận các giao dịch nhận tiền / lương',
            value: provider.autoAddIncome,
            onChanged: (val) => provider.setAutoAddIncome(val),
          ),
          const Divider(height: 1, indent: 56),
          _buildToggleTile(
            icon: Icons.pending_actions_rounded,
            iconColor: AppColors.warning,
            title: 'Yêu cầu xác nhận trước khi lưu',
            subtitle: 'Đưa vào danh sách chờ duyệt thay vì lưu thẳng',
            value: provider.showConfirmation,
            onChanged: (val) => provider.setShowConfirmation(val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ─── 4. BANKS GRID ───
  Widget _buildBanksGrid(AutoExpenseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _supportedBanks.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 52),
            itemBuilder: (context, index) {
              final bank = _supportedBanks[index];
              final source = bank['source'] as String;
              final name = bank['name'] as String;
              final color = bank['color'] as Color;
              final initials = bank['initials'] as String;
              final isEnabled = provider.isBankEnabled(source);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  isEnabled ? 'Đang nhận diện' : 'Đang tạm dừng',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isEnabled ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                trailing: Switch.adaptive(
                  value: isEnabled,
                  onChanged: (val) => provider.setBankEnabled(source, val),
                  activeThumbColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── 5. LOGS & PENDING LIST ───
  Widget _buildLogsCard(AutoExpenseProvider provider) {
    final processed = provider.processedNotifications;
    final pending = provider.pendingNotifications;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          TabBar(
            controller: _logTabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Đã xử lý (${processed.length})'),
              Tab(text: 'Chờ duyệt (${pending.length})'),
            ],
          ),
          SizedBox(
            height: 240,
            child: TabBarView(
              controller: _logTabController,
              children: [
                _buildLogList(processed, false),
                _buildLogList(pending, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List items, bool isPending) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                isPending ? 'Không có giao dịch nào đang chờ duyệt' : 'Chưa có thông báo ngân hàng gần đây',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final isIncome = item.isIncome;
        final formattedAmount =
            '${isIncome ? '+' : '-'}${_currencyFormatter.format(item.amount.toInt())} ₫';

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.incomeColor.withValues(alpha: 0.15)
                  : AppColors.expenseColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isIncome ? AppColors.incomeColor : AppColors.expenseColor,
              size: 16,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.sourceName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                formattedAmount,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isIncome ? AppColors.incomeColor : AppColors.expenseColor,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.description.isNotEmpty ? item.description : item.rawTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              Text(
                DateFormat('HH:mm dd/MM').format(item.timestamp),
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 6. SECURITY CARD ───
  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quyền riêng tư là ưu tiên hàng đầu: Ứng dụng chỉ đọc số tiền và nội dung thanh toán để ghi nhận tài chính. Không bao giờ thu thập mật khẩu, mã OTP hay lưu giữ thông tin thẻ của bạn.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
