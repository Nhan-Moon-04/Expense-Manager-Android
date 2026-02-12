import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'constants/admin_colors.dart';
import 'constants/admin_strings.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/admin_user_provider.dart';
import 'providers/admin_stats_provider.dart';
import 'providers/admin_notification_provider.dart';
import 'screens/login/admin_login_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'screens/users/user_list_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/notifications/notification_management_screen.dart';
import 'widgets/admin_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider()),
        ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
      ],
      child: MaterialApp(
        title: AdminStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AdminColors.accent,
            primary: AdminColors.accent,
            surface: Colors.white,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AdminColors.background,
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AdminColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AdminColors.accent, width: 2),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Chuyen huong giua Login va Main dua tren auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isAuthenticated) {
          return const AdminMainScreen();
        }

        return const AdminLoginScreen();
      },
    );
  }
}

/// Man hinh chinh admin - sidebar + content
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    UserListScreen(),
    StatisticsScreen(),
    NotificationManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminAuthProvider>().admin;
    double screenWidth = MediaQuery.of(context).size.width;

    // Responsive: neu nho hon 800px thi dung drawer thay vi sidebar co dinh
    bool useDrawer = screenWidth < 800;

    return Scaffold(
      appBar: useDrawer
          ? AppBar(
              title: const Text(AdminStrings.appName),
              backgroundColor: AdminColors.sidebarBg,
              foregroundColor: Colors.white,
            )
          : null,
      drawer: useDrawer
          ? Drawer(
              child: AdminDrawer(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
                adminName: admin?.fullName ?? '',
                adminEmail: admin?.email ?? '',
                onLogout: () => _handleLogout(context),
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar co dinh cho desktop
          if (!useDrawer)
            AdminDrawer(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              adminName: admin?.fullName ?? '',
              adminEmail: admin?.email ?? '',
              onLogout: () => _handleLogout(context),
            ),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dang xuat?'),
        content: const Text('Ban co chac muon dang xuat khoi Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminAuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text(
              'Dang Xuat',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
