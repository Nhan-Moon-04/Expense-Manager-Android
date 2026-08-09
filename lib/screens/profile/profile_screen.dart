import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../statistics/statistics_screen.dart';
import '../wallets/wallet_management_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<SettingsProvider>().currencyFormat;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (AppColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer2<AuthProvider, ExpenseProvider>(
          builder: (context, authProvider, expenseProvider, child) {
            final user = authProvider.user;

            return SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          // Profile Header
                          _buildProfileHeader(user),
                          const SizedBox(height: 20),

                          // Balance card
                          _buildBalanceCard(expenseProvider, currencyFormat),
                          const SizedBox(height: 24),

                          // Menu items
                          _buildMenuSection(
                            title: AppStrings.settings,
                            items: [
                              _buildMenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                title: AppStrings.walletManagement,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WalletManagementScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.bar_chart_rounded,
                                title: AppStrings.statistics,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StatisticsScreen(),
                                    ),
                                  );
                                },
                              ),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, _) => _buildMenuItem(
                                  icon: settings.isDarkMode
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  title: AppStrings.theme,
                                  trailing: Switch(
                                    value: settings.isDarkMode,
                                    onChanged: (value) {
                                      settings.setThemeMode(
                                        value ? ThemeMode.dark : ThemeMode.light,
                                      );
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                ),
                              ),
                              Consumer<SettingsProvider>(
                                builder: (context, settings, _) => _buildMenuItem(
                                  icon: Icons.language_rounded,
                                  title: AppStrings.language,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      settings.languageDisplayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showLanguagePicker(context),
                                ),
                              ),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                title: AppStrings.settings,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.notifications_outlined,
                                title: AppStrings.notifications,
                                trailing: Switch(
                                  value: true,
                                  onChanged: (value) {},
                                  activeColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildMenuSection(
                            title: AppStrings.otherSection,
                            items: [
                              _buildMenuItem(
                                icon: Icons.info_outline_rounded,
                                title: AppStrings.about,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.help_outline_rounded,
                                title: AppStrings.help,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HelpScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Logout button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              icon: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                              label: Text(
                                AppStrings.logout,
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: user?.avatarUrl == null || (user?.avatarUrl ?? '').isEmpty
                ? const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                ? Image.network(
                    user.avatarUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user.fullName),
                  )
                : _buildAvatarFallback(user?.fullName ?? 'U'),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user?.fullName ?? AppStrings.defaultUserName,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    final trimmed = name.trim();
    String initials = 'U';
    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        initials = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ExpenseProvider expenseProvider, dynamic currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.totalBalance,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  layoutBuilder:
                      (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                  child: Text(
                    _isBalanceVisible
                        ? currencyFormat.format(
                            expenseProvider.totalBalance,
                          )
                        : '••••••••',
                    key: ValueKey(_isBalanceVisible),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isBalanceVisible = !_isBalanceVisible;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isBalanceVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.selectLanguage,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text('Tiếng Việt', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                trailing: settings.language == 'vi'
                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setLanguage('vi');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text('English', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                trailing: settings.language == 'en'
                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setLanguage('en');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logout, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
