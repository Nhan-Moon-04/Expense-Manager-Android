import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/note_provider.dart';
import 'providers/group_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auto_expense_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/push_notification_service.dart';
import 'services/fcm_service.dart';

/// Background message handler - MUST be top-level function
/// Runs in a separate isolate when app is terminated/background
/// This is what makes notifications work even when app is closed (like banking apps)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in this isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  if (notification == null) return;

  // Show local notification directly (PushNotificationService is not available in background isolate)
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  const androidDetails = AndroidNotificationDetails(
    'fcm_high_importance_channel',
    'Thông báo quan trọng',
    channelDescription: 'Thông báo từ quản trị viên và hệ thống',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
    // Show on lock screen
    visibility: NotificationVisibility.public,
    // Full screen intent for urgent notifications
    fullScreenIntent: true,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    notification.title ?? 'Thông báo',
    notification.body ?? '',
    notificationDetails,
    payload: jsonEncode(message.data),
  );
}

/// Create the high-importance notification channel that matches
/// the one declared in AndroidManifest.xml for system-delivered FCM notifications
Future<void> _createFCMNotificationChannel() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidPlugin != null) {
    // This channel MUST match the ID in AndroidManifest.xml
    // "com.google.firebase.messaging.default_notification_channel_id"
    // When app is KILLED and FCM sends a notification message,
    // Android system uses this channel to display it automatically.
    // This is exactly how Zalo, banking apps, etc. work.
    const channel = AndroidNotificationChannel(
      'fcm_high_importance_channel', // Must match AndroidManifest.xml
      'Thông báo quan trọng',
      description: 'Thông báo từ quản trị viên và hệ thống',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(channel);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler BEFORE any other FCM calls
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create the FCM notification channel (MUST be done before any notification arrives)
  // This channel is used by Android system to show FCM notifications when app is killed
  await _createFCMNotificationChannel();

  await initializeDateFormatting('vi_VN', null);

  // Load settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  // Initialize push notifications (local)
  await PushNotificationService().initialize();

  // Initialize Firebase Cloud Messaging (remote from admin)
  await FCMService().initialize();

  runApp(MyApp(settingsProvider: settingsProvider));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  const MyApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider2<
          ExpenseProvider,
          WalletProvider,
          AutoExpenseProvider
        >(
          create: (_) => AutoExpenseProvider(),
          update: (_, expenseProvider, walletProvider, autoExpenseProvider) {
            autoExpenseProvider!.setExpenseProvider(expenseProvider);
            autoExpenseProvider.setWalletProvider(walletProvider);
            return autoExpenseProvider;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          // Sync dark mode flag so AppColors returns correct colors
          AppColors.setDarkMode(settingsProvider.isDarkMode);

          // Build text theme with Inter font
          final baseTextTheme = GoogleFonts.interTextTheme(
            settingsProvider.isDarkMode
                ? ThemeData.dark().textTheme
                : ThemeData.light().textTheme,
          );

          return MaterialApp(
            // Force full rebuild when language or theme changes
            key: ValueKey(
              '${settingsProvider.language}_${settingsProvider.themeMode}',
            ),
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: ThemeData(
              textTheme: baseTextTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                error: AppColors.error,
                surface: Colors.white,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              scaffoldBackgroundColor: AppColors.background,
              cardTheme: CardThemeData(
                elevation: 0,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.borderColor,
                    width: 1,
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              dividerTheme: DividerThemeData(
                color: AppColors.dividerColor,
                thickness: 1,
                space: 0,
              ),
              bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: AppColors.cardBackground,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                labelStyle: GoogleFonts.inter(fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: AppColors.borderColor),
              ),
            ),
            darkTheme: ThemeData(
              textTheme: baseTextTheme,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                error: AppColors.error,
                surface: const Color(0xFF1C1C34),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              brightness: Brightness.dark,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              scaffoldBackgroundColor: const Color(0xFF0C0C14),
              cardTheme: CardThemeData(
                elevation: 0,
                color: const Color(0xFF1C1C34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFF334155),
                    width: 1,
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF1C1C34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              popupMenuTheme: const PopupMenuThemeData(
                color: Color(0xFF1C1C34),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: const Color(0xFF1C1C34),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFF1E293B),
                thickness: 1,
                space: 0,
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, child) {
        // Show splash screen while checking auth & settings state
        if (!authProvider.isInitialized || !settingsProvider.isLoaded) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.appDescription,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Navigate based on auth state & app lock state
        if (authProvider.user != null) {
          if (!_isUnlocked) {
            return LoginScreen(
              onUnlocked: () {
                setState(() {
                  _isUnlocked = true;
                });
              },
            );
          }
          return const HomeScreen();
        }

        return LoginScreen(
          onUnlocked: () {
            setState(() {
              _isUnlocked = true;
            });
          },
        );
      },
    );
  }
}
