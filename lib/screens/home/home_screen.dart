import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auto_expense_provider.dart';
import '../expenses/expense_list_screen.dart';
import '../notes/notes_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: AppStrings.expenses,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_outlined),
              activeIcon: Icon(Icons.note),
              label: AppStrings.notes,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: AppStrings.groups,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
