import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // Delay load to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadGroups() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<GroupProvider>(
        context,
        listen: false,
      ).listenToGroups(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async => _loadGroups(),
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildGroupsList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhóm của bạn',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                return Text(
                  '${groupProvider.groups.length} nhóm đang hoạt động',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showJoinGroupDialog,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        double totalContribution = 0;
        int activeTargets = 0;

        for (var group in groupProvider.groups) {
          totalContribution += group.totalIncome;
          if (group.targetAmount != null && group.targetAmount! > 0) {
            activeTargets++;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.savings_rounded,
                title: 'Tổng đóng góp',
                value: currencyFormat.format(totalContribution),
                gradient: AppColors.incomeGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.flag_rounded,
                title: 'Mục tiêu',
                value: '$activeTargets đang thực hiện',
                gradient: AppColors.primaryGradient,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_rounded,
            label: 'Tạo nhóm',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.login_rounded,
            label: 'Tham gia',
            onTap: _showJoinGroupDialog,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.textHint.withValues(alpha: 0.3)),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.groups.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildGroupCard(groupProvider.groups[index], index);
            }, childCount: groupProvider.groups.length),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có nhóm nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo nhóm mới hoặc tham gia bằng mã mời',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group, int index) {
    final bool hasTarget =
        group.targetAmount != null && group.targetAmount! > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildGroupAvatar(group),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.members.length} thành viên',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      group.inviteCode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        letterSpacing: 1,
                                      ),
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
                          size: 28,
                        ),
                      ],
                    ),
                    if (hasTarget) ...[
                      const SizedBox(height: 16),
                      _buildTargetProgress(group),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Đã góp',
                        value: currencyFormat.format(group.totalIncome),
                        color: AppColors.incomeColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.textHint.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Đã chi',
                        value: currencyFormat.format(group.totalExpense),
                        color: AppColors.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(GroupModel group) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: group.avatarUrl == null
            ? const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: group.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: group.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildAvatarPlaceholder(group.name),
              )
            : _buildAvatarPlaceholder(group.name),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
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
          _getInitials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words.first[0]}${words.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildTargetProgress(GroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  group.targetDescription ?? 'Mục tiêu nhóm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${(group.targetProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: group.targetProgress,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${currencyFormat.format(group.totalIncome)} / ${currencyFormat.format(group.targetAmount)}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tham gia nhóm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã mời 6 ký tự để tham gia nhóm',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    letterSpacing: 8,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Consumer<GroupProvider>(
                  builder: (context, groupProvider, child) {
                    return ElevatedButton(
                      onPressed: groupProvider.isLoading
                          ? null
                          : () async {
                              if (codeController.text.trim().length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mã nhóm phải có 6 ký tự'),
                                  ),
                                );
                                return;
                              }

                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              bool success = await groupProvider.joinGroup(
                                codeController.text.trim().toUpperCase(),
                                authProvider.user!.uid,
                                displayName: authProvider.user!.fullName,
                                avatarUrl: authProvider.user!.avatarUrl,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Tham gia nhóm thành công!'
                                          : groupProvider.error ??
                                                'Đã có lỗi xảy ra',
                                    ),
                                    backgroundColor: success
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: groupProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Tham gia nhóm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
