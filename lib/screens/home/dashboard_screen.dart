import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/expense_model.dart';
import '../../services/voice_expense_service.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reminders/add_reminder_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wallets/wallet_management_screen.dart';
import '../wallets/wallet_detail_screen.dart';
import '../../models/wallet_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  NumberFormat get currencyFormat =>
      context.read<SettingsProvider>().currencyFormat;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isBalanceVisible = false;

  // FAB expansion
  late AnimationController _fabAnimationController;
  late Animation<double> _fabExpandAnimation;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabExpandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );

    // Delay _loadData to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final userId = authProvider.user!.uid;
      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );
      final reminderProvider = Provider.of<ReminderProvider>(
        context,
        listen: false,
      );

      expenseProvider.loadTodayExpenses(userId);
      expenseProvider.loadMonthExpenses(userId);
      expenseProvider.syncWidgetData(authProvider.user!.fullName);
      reminderProvider.listenToReminders(userId);
      reminderProvider.loadUpcomingReminders(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (AppColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildBalanceCard(),
                          const SizedBox(height: 14),
                          _buildMomoStyleWalletsCard(),
                          const SizedBox(height: 18),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildUpcomingReminders(),
                          const SizedBox(height: 20),
                          _buildRecentExpenses(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildExpandableFAB(),
      ),
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _openVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceListeningSheet(
        onResult: (result) {
          Navigator.pop(ctx);
          final walletProvider = Provider.of<WalletProvider>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                isIncome: result.isIncome,
                initialAmount: result.amount,
                initialDescription: result.description,
                defaultWalletId: walletProvider.primaryWallet?.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableFAB() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Overlay to close when tapping outside
          if (_isFabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFab,
                behavior: HitTestBehavior.opaque,
              ),
            ),
          // Income button (top-left of FAB)
          _buildMiniFab(
            icon: Icons.arrow_downward_rounded,
            label: AppStrings.income,
            color: AppColors.success,
            offset: const Offset(-70, -70),
            onTap: () {
              _toggleFab();
              final walletProvider = Provider.of<WalletProvider>(
                context,
                listen: false,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    isIncome: true,
                    defaultWalletId: walletProvider.primaryWallet?.id,
                  ),
                ),
              );
            },
          ),
          // Expense button (directly above FAB)
          _buildMiniFab(
            icon: Icons.arrow_upward_rounded,
            label: AppStrings.expense,
            color: AppColors.error,
            offset: const Offset(0, -95),
            onTap: () {
              _toggleFab();
              final walletProvider = Provider.of<WalletProvider>(
                context,
                listen: false,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    isIncome: false,
                    defaultWalletId: walletProvider.primaryWallet?.id,
                  ),
                ),
              );
            },
          ),
          // Voice input button (left of FAB)
          _buildMiniFab(
            icon: Icons.mic_rounded,
            label: 'Giọng nói',
            color: const Color(0xFF8B5CF6),
            offset: const Offset(-95, -10),
            onTap: () {
              _toggleFab();
              _openVoiceInput();
            },
          ),
          // Main FAB button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'dashboard_fab',
              onPressed: _toggleFab,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: AnimatedBuilder(
                animation: _fabExpandAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _fabExpandAnimation.value * 0.785, // 45 degrees
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String label,
    required Color color,
    required Offset offset,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _fabExpandAnimation,
      builder: (context, child) {
        final dx = offset.dx * _fabExpandAnimation.value;
        final dy = offset.dy * _fabExpandAnimation.value;
        return Positioned(
          right: -dx,
          bottom: -dy,
          child: Opacity(
            opacity: _fabExpandAnimation.value,
            child: Transform.scale(
              scale: _fabExpandAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor, width: 0.5),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final greeting = _getGreeting();
        return Row(
          children: [
            // Circle avatar with gradient ring border
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBackground,
                  gradient: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                      ? const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 46,
                          height: 46,
                          placeholder: (context, url) => Center(
                            child: Text(
                              _getInitials(user.fullName),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user.fullName),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(user?.fullName ?? 'U'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user?.fullName ?? AppStrings.defaultUserName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            _buildNotificationButton(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer3<AuthProvider, ExpenseProvider, WalletProvider>(
      builder: (context, authProvider, expenseProvider, walletProvider, child) {
        final balance = walletProvider.wallets.isEmpty
            ? expenseProvider.totalBalance
            : walletProvider.getTotalBalance(expenseProvider.expenses);
        final growthPercent = expenseProvider.monthGrowthPercent;
        final isGrowthPositive = growthPercent >= 0;

        // Determine growth label
        String growthLabel;
        if (growthPercent > 10) {
          growthLabel = AppStrings.growthGood;
        } else if (growthPercent >= 0) {
          growthLabel = AppStrings.growthStable;
        } else if (growthPercent > -10) {
          growthLabel = AppStrings.growthSlightDrop;
        } else {
          growthLabel = AppStrings.growthDrop;
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E1B4B),
                Color(0xFF312E81),
                Color(0xFF2563EB),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Ambient luminous orb - Top Right
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF60A5FA).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Ambient luminous orb - Bottom Left
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFA78BFA).withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content Layer
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.totalBalance,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildBalanceMenuButton(balance),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
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
                                        style: GoogleFonts.inter(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                          height: 1.1,
                                        ),
                                      )
                                    : Text(
                                        '••••••••',
                                        key: const ValueKey('hidden'),
                                        style: GoogleFonts.inter(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 4,
                                          height: 1.1,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
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
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildBalanceTrend(
                            isPositive: isGrowthPositive,
                            label: growthLabel,
                            percent: growthPercent,
                          ),
                          const Spacer(),
                          // Inline Income indicator
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.south_west_rounded,
                                    color: Color(0xFF34D399),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _isBalanceVisible
                                          ? currencyFormat.format(expenseProvider.monthIncome)
                                          : '••••••',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF34D399),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Inline Expense indicator
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.north_east_rounded,
                                    color: Color(0xFFFB7185),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _isBalanceVisible
                                          ? currencyFormat.format(expenseProvider.monthTotal)
                                          : '••••••',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFB7185),
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceMenuButton(double balance) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: Colors.white.withValues(alpha: 0.8),
        size: 22,
      ),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'toggle':
            setState(() {
              _isBalanceVisible = !_isBalanceVisible;
            });
            break;
          case 'refresh':
            _loadData();
            break;
          case 'details':
            // Navigate to expense list / details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExpenseListScreen(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                _isBalanceVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                _isBalanceVisible
                    ? AppStrings.hideBalance
                    : AppStrings.showBalance,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(AppStrings.refresh),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(AppStrings.viewDetails),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceTrend({
    required bool isPositive,
    required String label,
    required double percent,
  }) {
    // High-contrast executive fintech pill colors
    final gradientColors = isPositive
        ? const [Color(0xFF059669), Color(0xFF10B981)] // Luminous Emerald
        : const [Color(0xFFE11D48), Color(0xFFF43F5E)]; // Vibrant Rose Red
    final shadowColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            '${percent.abs().toStringAsFixed(0)}% $label',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.remove_rounded,
              label: AppStrings.expense,
              color: AppColors.expenseColor,
              gradient: AppColors.expenseGradient,
              onTap: () {
                final walletProvider = Provider.of<WalletProvider>(
                  context,
                  listen: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      defaultWalletId: walletProvider.primaryWallet?.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              icon: Icons.add_rounded,
              label: AppStrings.income,
              color: AppColors.incomeColor,
              gradient: AppColors.incomeGradient,
              onTap: () {
                final walletProvider = Provider.of<WalletProvider>(
                  context,
                  listen: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      isIncome: true,
                      defaultWalletId: walletProvider.primaryWallet?.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              icon: Icons.notifications_active_outlined,
              label: AppStrings.reminders,
              color: AppColors.warning,
              gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemindersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingReminders() {
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        // Show enabled (active + not completed) reminders, sorted by time
        final allEnabled =
            reminderProvider.enabledReminders
                .where((r) => r.reminderTime.isAfter(DateTime.now()))
                .toList()
              ..sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
        final reminders = allEnabled.take(3).toList();
        if (reminders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.upcomingReminders,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RemindersScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppStrings.viewAll,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reminders.map(
              (reminder) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddReminderScreen(reminder: reminder),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'HH:mm - dd/MM',
                                  ).format(reminder.reminderTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpenses() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final expenses = expenseProvider.expenses.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.recentTransactions,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (expenses.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpenseListScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppStrings.viewAll,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 36,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.noTransactions,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.addFirstExpense,
                        style: GoogleFonts.inter(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                ),
                child: Column(
                  children: expenses
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildExpenseItem(
                          entry.value,
                          isLast: entry.key == expenses.length - 1,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(color: AppColors.dividerColor, width: 0.5),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (expense.hasBankSource
                              ? _getBankColor(expense.bankSource!)
                              : categoryColor)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: expense.hasBankSource
                    ? Icon(
                        _getBankIcon(expense.bankSource!),
                        color: _getBankColor(expense.bankSource!),
                        size: 20,
                      )
                    : Icon(
                        _getCategoryIcon(expense.category),
                        color: categoryColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Tự động',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expense.subtitleText ??
                          DateFormat('dd/MM/yyyy').format(expense.date),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"}${currencyFormat.format(expense.amount)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('HH:mm').format(expense.date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.greetingMorning;
    if (hour < 18) return AppStrings.greetingAfternoon;
    return AppStrings.greetingEvening;
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _getBankColor(String bankSource) {
    switch (bankSource.toLowerCase()) {
      case 'momo':
        return const Color(0xFFAE2070);
      case 'vcb':
      case 'vietcombank':
        return const Color(0xFF1B6E37);
      case 'mbbank':
        return const Color(0xFF1E4DB7);
      case 'techcombank':
        return const Color(0xFFED1C24);
      case 'bidv':
        return const Color(0xFF2E3192);
      case 'vietinbank':
        return const Color(0xFF1D4A94);
      case 'tpbank':
        return const Color(0xFF652D86);
      case 'acb':
        return const Color(0xFF1A2B6D);
      case 'sacombank':
        return const Color(0xFF003087);
      case 'agribank':
        return const Color(0xFFE31837);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildMomoStyleWalletsCard() {
    return Consumer2<WalletProvider, ExpenseProvider>(
      builder: (context, walletProvider, expenseProvider, child) {
        final wallets = walletProvider.wallets;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Scrollable Row of Wallets with vertical dividers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (int i = 0; i < wallets.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 38,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: AppColors.borderColor.withValues(alpha: 0.7),
                        ),
                      _buildWalletRowItem(
                        context,
                        wallets[i],
                        expenseProvider,
                        walletProvider,
                      ),
                    ],
                    // Add wallet button at the end
                    Container(
                      width: 1,
                      height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppColors.borderColor.withValues(alpha: 0.7),
                    ),
                    _buildAddWalletRowItem(context),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bottom MoMo-style Highlight Button ("Trung Tâm Quản Lý Ví của...")
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletManagementScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Trung Tâm Quản Lý Tài Chính',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletRowItem(
    BuildContext context,
    WalletModel wallet,
    ExpenseProvider expenseProvider,
    WalletProvider walletProvider,
  ) {
    final balance = walletProvider.getWalletBalance(
      wallet.id,
      expenseProvider.expenses,
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletDetailScreen(wallet: wallet),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Wallet Icon/Logo + Name
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: (wallet.isPrimary
                            ? AppColors.primary
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    wallet.isPrimary
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                    size: 12,
                    color: wallet.isPrimary
                        ? AppColors.primary
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  wallet.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (wallet.isPrimary) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Chính',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            // Bottom Row: Balance + Chevron >
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isBalanceVisible
                      ? currencyFormat.format(balance)
                      : '••••••',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddWalletRowItem(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WalletManagementScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Thêm ví',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tùy chỉnh',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// VOICE LISTENING SHEET
// ═══════════════════════════════════════════════════════════
class VoiceListeningSheet extends StatefulWidget {
  final void Function(VoiceExpenseResult result) onResult;

  const VoiceListeningSheet({super.key, required this.onResult});

  @override
  State<VoiceListeningSheet> createState() => _VoiceListeningSheetState();
}

class _VoiceListeningSheetState extends State<VoiceListeningSheet>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasError = false;
  bool _needsPermission = false;
  String _transcribedText = '';
  VoiceExpenseResult? _parsedResult;
  String? _errorMessage;
  String _detectedLocaleId = 'vi_VN';
  late final TextEditingController _textController;

  // Mic pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Wave bars animation
  late AnimationController _waveController;
  late List<Animation<double>> _waveAnims;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waveAnims = List.generate(5, (i) {
      final start = i * 0.15;
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(start, (start + 0.55).clamp(0, 1), curve: Curves.easeInOut),
        ),
      );
    });

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      // 1. Kiểm tra và xin quyền microphone trước
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          if (mounted) {
            setState(() {
              _needsPermission = true;
              _hasError = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _needsPermission = false;
          _hasError = false;
          _errorMessage = null;
        });
      }

      // 2. Khởi tạo Speech Recognizer
      _isInitialized = await _speech.initialize(
        debugLogging: true,
        onStatus: (status) {
          debugPrint('🎙️ [Speech] Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              _stopAnimations();
              _tryParse();
            }
          } else if (status == 'listening') {
            if (mounted) {
              setState(() => _isListening = true);
              _startAnimations();
            }
          }
        },
        onError: (error) {
          debugPrint('🎙️ [Speech] Error: ${error.errorMsg}');
          if (mounted) {
            Permission.microphone.isGranted.then((granted) {
              if (mounted) {
                if (!granted) {
                  setState(() {
                    _isListening = false;
                    _needsPermission = true;
                  });
                } else {
                  setState(() {
                    _isListening = false;
                    _hasError = true;
                    _errorMessage = error.errorMsg;
                  });
                }
                _stopAnimations();
              }
            });
          }
        },
      );

      String localeId = 'vi_VN';
      try {
        final locales = await _speech.locales();
        debugPrint('🎙️ [Speech] Available locales: ${locales.map((l) => l.localeId).join(', ')}');
        final viLocale = locales.where((l) => l.localeId.toLowerCase().startsWith('vi')).firstOrNull;
        if (viLocale != null) {
          localeId = viLocale.localeId;
        } else if (locales.isNotEmpty) {
          localeId = locales.first.localeId;
        }
      } catch (_) {}
      _detectedLocaleId = localeId;
      debugPrint('🎙️ [Speech] Using locale: $_detectedLocaleId');

      if (!_isInitialized && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Thiết bị chưa bật Dịch vụ nhận diện giọng nói (Google Voice Recognition).';
        });
        return;
      }

      if (_isInitialized && mounted) {
        _startListening();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _startListening([String? localeId]) async {
    if (!_isInitialized) return;
    final targetLocale = localeId ?? _detectedLocaleId;
    debugPrint('🎙️ [Speech] Starting listen with locale: $targetLocale');
    setState(() {
      _isListening = true;
      _hasError = false;
      _transcribedText = '';
      _parsedResult = null;
    });
    _textController.clear();
    _startAnimations();

    await _speech.listen(
      onResult: (result) {
        debugPrint('🎙️ [Speech] Recognized: "${result.recognizedWords}" (final: ${result.finalResult})');
        if (mounted) {
          setState(() {
            _transcribedText = result.recognizedWords;
            _textController.text = result.recognizedWords;
            _parsedResult = VoiceExpenseService.parse(_transcribedText);
          });
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: targetLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  Future<void> _stopListening() async {
    debugPrint('🎙️ [Speech] Manual stop requested');
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _stopAnimations();
      _tryParse();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  void _tryParse() {
    if (_transcribedText.isNotEmpty) {
      setState(() {
        _parsedResult = VoiceExpenseService.parse(_transcribedText);
      });
    }
  }

  void _confirm() {
    if (_parsedResult != null) {
      widget.onResult(_parsedResult!);
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _textController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Nhập chi tiêu bằng giọng nói',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nói tự nhiên: "Chi 50k cafe" hoặc "Thu 2 triệu lương"',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Mic button with pulse
          if (_needsPermission)
            _buildPermissionState()
          else if (_hasError)
            _buildErrorState()
          else ...[
            // Animated mic
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnim.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)]
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? const Color(0xFF8B5CF6)
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Wave bars (animated when listening)
            if (_isListening)
              _buildWaveBars()
            else
              Text(
                _isListening ? '' : 'Nhấn mic để bắt đầu',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

            // Transcribed / Input text field
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening ? const Color(0xFF8B5CF6) : AppColors.borderColor,
                  width: _isListening ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.edit_note_rounded,
                    size: 20,
                    color: _isListening ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Đang lắng nghe...' : 'Nói hoặc nhập: "chi 50k cafe"',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _transcribedText = val;
                          _parsedResult = VoiceExpenseService.parse(val);
                        });
                      },
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _textController.clear();
                        setState(() {
                          _transcribedText = '';
                          _parsedResult = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Parsed result preview
            if (_parsedResult != null) ...[
              const SizedBox(height: 12),
              _buildParsedPreview(_parsedResult!),
            ],

            const SizedBox(height: 20),

            // Confirm button
            if (_parsedResult != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _parsedResult!.isIncome
                          ? AppColors.incomeGradient
                          : AppColors.expenseGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_parsedResult!.isIncome
                                ? AppColors.incomeColor
                                : AppColors.expenseColor)
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Tiếp tục điền thông tin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),

            if (!_isListening && _transcribedText.isNotEmpty)
              TextButton.icon(
                onPressed: _startListening,
                icon: Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  'Thử lại',
                  style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveBars() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (ctx, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final height = 8.0 + _waveAnims[i].value * 28.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(
                    alpha: 0.4 + _waveAnims[i].value * 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildParsedPreview(VoiceExpenseResult result) {
    final color = result.isIncome ? AppColors.incomeColor : AppColors.expenseColor;
    final typeLabel = result.isIncome ? 'Thu nhập' : 'Chi tiêu';
    final typeIcon =
        result.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amountText = result.amount != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)
            .format(result.amount)
        : 'Chưa xác định';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                typeLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                amountText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.settings_voice_rounded, color: AppColors.warning, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          'Cần bật Nhận diện giọng nói Google',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Máy chưa chọn Google làm dịch vụ nhận diện giọng nói.\nBấm nút bên dưới để vào cài đặt và chọn Google.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                const channel = MethodChannel('com.example.expense_manager_android/notifications');
                await channel.invokeMethod('openVoiceInputSettings');
              } catch (_) {}
            },
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: Text(
              'Mở Cài đặt Nhập giọng nói',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _hasError = false;
              _isListening = false;
            });
            _initSpeech();
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text('Thử lại sau khi đã bật', style: GoogleFonts.inter(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPermissionState() {
    return Column(
      children: [
        // Icon
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                const Color(0xFF7C3AED).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Color(0xFF8B5CF6),
            size: 38,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Cần quyền Microphone',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ứng dụng cần quyền truy cập microphone\nđể nhận diện giọng nói của bạn',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Grant permission button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Permission.microphone.request();
                if (result.isGranted) {
                  if (mounted) {
                    setState(() => _needsPermission = false);
                    _initSpeech();
                  }
                } else if (result.isPermanentlyDenied) {
                  // User chọn "Không hỏi lại" → mở settings
                  await openAppSettings();
                }
              },
              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              label: Text(
                'Cấp quyền Microphone',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Open settings button (for permanently denied case)
        TextButton.icon(
          onPressed: () async {
            await openAppSettings();
          },
          icon: Icon(Icons.settings_rounded,
              size: 15, color: AppColors.textSecondary),
          label: Text(
            'Mở Cài đặt ứng dụng',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
