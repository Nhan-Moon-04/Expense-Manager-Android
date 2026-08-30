import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/wallet_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/settings_provider.dart';
import 'wallet_detail_screen.dart';
import 'widgets/transfer_money_sheet.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  String _selectedCategoryFilter = 'Tất cả';
  final PageController _cardPageController = PageController(viewportFraction: 0.88);
  int _currentCardIndex = 0;

  final List<String> _categoryFilters = [
    'Tất cả',
    'Tài khoản ngân hàng',
    'Ví điện tử',
    'Tiền mặt',
    'Sổ tiết kiệm',
  ];

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  void _showAddWalletDialog(BuildContext context) {
    final nameController = TextEditingController();
    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tạo Ví / Tài Khoản Mới',
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Tên ví hoặc ngân hàng',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Vietcombank, MoMo, Tiền mặt, Techcombank...',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.wallet_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Đặt làm ví chính mặc định',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Các khoản thu chi mặc định sẽ ghi vào ví này',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: isPrimary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => isPrimary = val),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                      if (authProvider.user == null) return;

                      final newWallet = WalletModel(
                        id: '',
                        userId: authProvider.user!.uid,
                        name: name,
                        isPrimary: isPrimary,
                      );

                      Navigator.pop(ctx);
                      final success = await walletProvider.createWallet(newWallet);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã tạo ví mới thành công!'), backgroundColor: AppColors.success),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Tạo Ví Mới', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer3<WalletProvider, ExpenseProvider, AuthProvider>(
            builder: (context, walletProvider, expenseProvider, authProvider, child) {
              final wallets = walletProvider.wallets;
              final allExpenses = expenseProvider.expenses;
              final totalNetWorth = walletProvider.getTotalBalance(allExpenses);

              final filteredWallets = _selectedCategoryFilter == 'Tất cả'
                  ? wallets
                  : wallets.where((w) => w.typeCategory == _selectedCategoryFilter).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Quản Lý Ví & Tài Khoản',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _showAddWalletDialog(context),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Digital Card Carousel
                  if (wallets.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PageView.builder(
                              controller: _cardPageController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: wallets.length,
                              onPageChanged: (idx) => setState(() => _currentCardIndex = idx),
                              itemBuilder: (context, index) {
                                final wallet = wallets[index];
                                final balance = walletProvider.getWalletBalance(wallet.id, allExpenses);
                                return _buildLuxuryDigitalCard(wallet, balance, currencyFormat);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Dots Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(wallets.length, (idx) {
                              final isCurrent = idx == _currentCardIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isCurrent ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.primary : AppColors.dividerColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                  // Total Net Worth & Action Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          _buildNetWorthSummary(totalNetWorth, wallets.length, currencyFormat),
                          const SizedBox(height: 16),
                          _buildQuickActionBar(context),
                          const SizedBox(height: 24),
                          // Category Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _categoryFilters.map((cat) {
                                final isSelected = _selectedCategoryFilter == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(
                                      cat,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    backgroundColor: AppColors.cardBackground,
                                    selectedColor: AppColors.primary,
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderColor),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedCategoryFilter = cat);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Wallet List Items
                  if (filteredWallets.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final wallet = filteredWallets[index];
                            final balance = walletProvider.getWalletBalance(wallet.id, allExpenses);
                            final percent = totalNetWorth > 0 ? (balance / totalNetWorth) * 100 : 0.0;
                            return _buildWalletRowItem(wallet, balance, percent, currencyFormat);
                          },
                          childCount: filteredWallets.length,
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text('Chưa có ví nào trong danh mục này', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── LUXURY DIGITAL CARD ───
  Widget _buildLuxuryDigitalCard(WalletModel wallet, double balance, NumberFormat format) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletDetailScreen(wallet: wallet)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: wallet.cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: wallet.cardGradient.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Brand Icon & Primary Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(wallet.brandIcon, color: Colors.white.withValues(alpha: 0.9), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      wallet.typeCategory,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (wallet.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Ví chính',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Card Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư khả dụng',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 2),
                Text(
                  format.format(balance),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            // Bottom Row: Wallet Name & Card Chip Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wallet.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.contactless_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── NET WORTH BANNER ───
  Widget _buildNetWorthSummary(double total, int count, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Tổng Tài Sản Tất Cả Ví',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                format.format(total),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: total >= 0 ? AppColors.incomeColor : AppColors.expenseColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count ví hoạt động',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTION BAR ───
  Widget _buildQuickActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Chuyển Tiền',
            color: AppColors.primary,
            onTap: () => TransferMoneySheet.show(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_card_rounded,
            title: 'Thêm Ví Mới',
            color: AppColors.accent,
            onTap: () => _showAddWalletDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WALLET ROW ITEM ───
  Widget _buildWalletRowItem(WalletModel wallet, double balance, double percent, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WalletDetailScreen(wallet: wallet)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: wallet.cardGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(wallet.brandIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),

                // Name & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              wallet.name,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (wallet.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.amber),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${wallet.typeCategory} • ${percent.toStringAsFixed(1)}% tổng tài sản',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(balance),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: balance >= 0 ? AppColors.textPrimary : AppColors.expenseColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textHint),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
