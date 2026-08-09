import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auto_expense_provider.dart';
import '../../providers/wallet_provider.dart';
import '../expenses/expense_list_screen.dart';
import '../notes/notes_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/update_dialog.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpenseListScreen(),
    const NotesScreen(),
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay initialization to after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      // Kiểm tra phiên bản khi mở app
      UpdateDialog.checkAndShow(context);
    });
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final userId = authProvider.user!.uid;

      // Initialize providers
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).listenToExpenses(userId);
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).listenToNotifications(userId);

      // Initialize wallet provider
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      walletProvider.ensurePrimaryWallet(userId);
      walletProvider.listenToWallets(userId);

      // Initialize auto expense listener with user ID
      final autoExpenseProvider = Provider.of<AutoExpenseProvider>(
        context,
        listen: false,
      );
      autoExpenseProvider.setUserId(userId);
      autoExpenseProvider.checkNotificationAccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bottomBarBackground,
          border: Border(
            top: BorderSide(
              color: AppColors.borderColor,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: AppStrings.home,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: AppStrings.expenses,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.sticky_note_2_outlined,
                  activeIcon: Icons.sticky_note_2_rounded,
                  label: AppStrings.notes,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: AppStrings.groups,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: AppStrings.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 0,
                  vertical: isSelected ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
