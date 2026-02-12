import 'package:flutter/material.dart';
import '../../constants/admin_colors.dart';
import '../../constants/admin_strings.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String adminName;
  final String adminEmail;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.adminName,
    required this.adminEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AdminColors.sidebarBg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AdminColors.accent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AdminStrings.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  adminName,
                  style: TextStyle(
                    color: AdminColors.sidebarText.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          // Menu items
          _buildMenuItem(0, Icons.dashboard_rounded, AdminStrings.dashboard),
          _buildMenuItem(1, Icons.people_rounded, AdminStrings.userManagement),
          _buildMenuItem(2, Icons.bar_chart_rounded, AdminStrings.statistics),
          _buildMenuItem(
            3,
            Icons.notifications_rounded,
            AdminStrings.notifications,
          ),
          const Spacer(),
          // Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                AdminStrings.logout,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AdminColors.sidebarText,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AdminColors.sidebarActiveText
                : AdminColors.sidebarText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AdminColors.sidebarActiveBg
            : Colors.transparent,
        onTap: () => onItemSelected(index),
      ),
    );
  }
}
