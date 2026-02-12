import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../models/expense_model.dart';
import 'create_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);

    // Delay load to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  void _loadGroupData() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.selectGroup(widget.group);
  }

  void _onScroll() {
    if (_scrollController.offset > 150 && !_isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = true);
    } else if (_scrollController.offset <= 150 && _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final group = groupProvider.selectedGroup ?? widget.group;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isOwner = group.ownerId == authProvider.user?.uid;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [_buildSliverAppBar(group, isOwner)];
            },
            body: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(group),
                      _buildExpensesTab(groupProvider),
                      _buildMembersTab(group),
                      _buildSplitTab(group, groupProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildSliverAppBar(GroupModel group, bool isOwner) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHeaderCollapsed ? 0 : 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isHeaderCollapsed ? 0 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _shareInviteCode,
        ),
        if (isOwner)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _isHeaderCollapsed ? 0 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupScreen(group: group),
                ),
              );
            },
          ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isHeaderCollapsed ? 0 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'leave') _showLeaveDialog();
            if (value == 'delete') _showDeleteDialog();
          },
          itemBuilder: (context) => [
            if (!isOwner)
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Rời nhóm', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            if (isOwner)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Xoá nhóm', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(group),
      ),
    );
  }

  Widget _buildHeaderBackground(GroupModel group) {
    final hasTarget = group.targetAmount != null && group.targetAmount! > 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildGroupAvatar(group),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.members.length} thành viên',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (hasTarget) ...[
                _buildTargetProgressCard(group),
              ] else ...[
                _buildBalanceCards(group),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(GroupModel group) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: group.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: group.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildAvatarPlaceholder(group.name),
                errorWidget: (context, url, error) =>
                    _buildAvatarPlaceholder(group.name),
              )
            : _buildAvatarPlaceholder(group.name),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
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

  Widget _buildTargetProgressCard(GroupModel group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.targetDescription ?? 'Mục tiêu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Text(
                '${(group.targetProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: group.targetProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(group.totalIncome),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '/ ${currencyFormat.format(group.targetAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards(GroupModel group) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: AppColors.incomeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã góp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(group.totalIncome),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: AppColors.expenseColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã chi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(group.totalExpense),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Giao dịch'),
          Tab(text: 'Thành viên'),
          Tab(text: 'Chia tiền'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(GroupModel group) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(group),
          const SizedBox(height: 20),
          _buildInviteCodeCard(group),
          const SizedBox(height: 20),
          if (group.targetAmount != null && group.targetAmount! > 0)
            _buildTargetDetailsCard(group),
        ],
      ),
    );
  }

  Widget _buildInfoCard(GroupModel group) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhóm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.description_rounded,
            label: 'Mô tả',
            value: group.description ?? 'Chưa có mô tả',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày tạo',
            value: DateFormat('dd/MM/yyyy').format(group.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Số dư',
            value: currencyFormat.format(
              group.totalIncome - group.totalExpense,
            ),
            valueColor: (group.totalIncome - group.totalExpense) >= 0
                ? AppColors.incomeColor
                : AppColors.expenseColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeCard(GroupModel group) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 12),
              Text(
                'Mã mời nhóm',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            group.inviteCode,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã mời')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Sao chép mã'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDetailsCard(GroupModel group) {
    final daysLeft = group.targetDeadline?.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mục tiêu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      group.targetDescription ?? 'Mục tiêu nhóm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTargetStat(
                  label: 'Mục tiêu',
                  value: currencyFormat.format(group.targetAmount),
                  icon: Icons.savings_rounded,
                ),
              ),
              Expanded(
                child: _buildTargetStat(
                  label: 'Còn thiếu',
                  value: currencyFormat.format(group.remainingAmount),
                  icon: Icons.pending_rounded,
                ),
              ),
              if (daysLeft != null)
                Expanded(
                  child: _buildTargetStat(
                    label: 'Còn lại',
                    value: '$daysLeft ngày',
                    icon: Icons.timer_rounded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExpensesTab(GroupProvider groupProvider) {
    final expenses = groupProvider.groupExpenses;

    if (expenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'Chưa có giao dịch',
        subtitle: 'Thêm giao dịch mới bằng nút + bên dưới',
      );
    }

    // Group by date
    Map<String, List<ExpenseModel>> groupedExpenses = {};
    for (var expense in expenses) {
      final dateKey = DateFormat('dd/MM/yyyy').format(expense.date);
      groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateKey = groupedExpenses.keys.elementAt(index);
        final dayExpenses = groupedExpenses[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...dayExpenses
                .map((expense) => _buildExpenseItem(expense))
                ,
          ],
        );
      },
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense) {
    final isIncome = expense.type == ExpenseType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.incomeColor : AppColors.expenseColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isIncome ? AppColors.incomeColor : AppColors.expenseColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ??
                      ExpenseModel.getCategoryName(expense.category),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(expense.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${currencyFormat.format(expense.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.incomeColor : AppColors.expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(GroupModel group) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        return _buildMemberItem(member, group.ownerId);
      },
    );
  }

  Widget _buildMemberItem(GroupMember member, String ownerId) {
    final isOwner = member.role == 'owner';
    final isAdmin = member.role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: member.avatarUrl == null
                  ? const LinearGradient(colors: AppColors.primaryGradient)
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: member.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          _buildMemberAvatarPlaceholder(member.displayName),
                    )
                  : _buildMemberAvatarPlaceholder(member.displayName),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName ?? 'Thành viên',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwner || isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOwner
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOwner ? 'Chủ nhóm' : 'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? AppColors.warning : AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Đóng góp: ${currencyFormat.format(member.contribution)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatarPlaceholder(String? name) {
    return Center(
      child: Text(
        _getInitials(name ?? '?'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSplitTab(GroupModel group, GroupProvider groupProvider) {
    final splits = groupProvider.calculateSplit();
    final perPerson = group.members.isNotEmpty
        ? group.totalExpense / group.members.length
        : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Tổng chi tiêu nhóm',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(group.totalExpense),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trung bình: ${currencyFormat.format(perPerson)}/người',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chi tiết chia tiền',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...splits.entries.map((entry) {
            final balance = entry.value;
            final isOwed = balance < 0;
            final member = group.members.firstWhere(
              (m) => m.userId == entry.key,
              orElse: () => GroupMember(
                userId: entry.key,
                role: 'member',
                joinedAt: DateTime.now(),
              ),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          (isOwed
                                  ? AppColors.incomeColor
                                  : AppColors.expenseColor)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isOwed
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isOwed
                          ? AppColors.incomeColor
                          : AppColors.expenseColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName ?? 'Thành viên',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOwed ? 'Được nhận lại' : 'Cần trả thêm',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(balance.abs()),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOwed
                          ? AppColors.incomeColor
                          : AppColors.expenseColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        heroTag: 'group_detail_fab',
        onPressed: _showAddTransactionSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _shareInviteCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<GroupProvider>(
        builder: (context, provider, child) {
          final group = provider.selectedGroup ?? widget.group;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mời bạn bè vào nhóm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chia sẻ mã này để mời người khác tham gia',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    group.inviteCode,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.inviteCode));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép mã mời')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Sao chép mã'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTransactionSheet() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    ExpenseType selectedType = ExpenseType.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
                  'Thêm giao dịch',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Đóng góp',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: selectedType == ExpenseType.income,
                        color: AppColors.incomeColor,
                        onTap: () =>
                            setState(() => selectedType = ExpenseType.income),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Chi tiêu',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: selectedType == ExpenseType.expense,
                        color: AppColors.expenseColor,
                        onTap: () =>
                            setState(() => selectedType = ExpenseType.expense),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Số tiền',
                    suffixText: '₫',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
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
                                final amount =
                                    double.tryParse(amountController.text) ?? 0;
                                if (amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Số tiền không hợp lệ'),
                                    ),
                                  );
                                  return;
                                }

                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final now = DateTime.now();

                                ExpenseModel expense = ExpenseModel(
                                  id: '',
                                  userId: authProvider.user!.uid,
                                  groupId: widget.group.id,
                                  amount: amount,
                                  type: selectedType,
                                  category: ExpenseCategory.other,
                                  description:
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  date: now,
                                  createdAt: now,
                                  updatedAt: now,
                                );

                                bool success = await groupProvider
                                    .addGroupExpense(expense);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Thêm giao dịch thành công'
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
                                'Thêm giao dịch',
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
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.textHint.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_forever_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Xoá nhóm'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn xoá nhóm "${widget.group.name}"?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác. Tất cả dữ liệu của nhóm sẽ bị xoá.',
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              return ElevatedButton(
                onPressed: groupProvider.isLoading
                    ? null
                    : () async {
                        bool success = await groupProvider.deleteGroup(
                          widget.group.id,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          if (success) {
                            Navigator.pop(context); // Go back to groups list
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã xoá nhóm thành công'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  groupProvider.error ?? 'Không thể xoá nhóm',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: groupProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Xoá nhóm'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = widget.group.ownerId == authProvider.user?.uid;

    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chủ nhóm không thể rời nhóm. Hãy chuyển quyền trước.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rời nhóm'),
        content: const Text('Bạn có chắc muốn rời khỏi nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              return ElevatedButton(
                onPressed: groupProvider.isLoading
                    ? null
                    : () async {
                        bool success = await groupProvider.leaveGroup(
                          widget.group.id,
                          authProvider.user!.uid,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          if (success) {
                            Navigator.pop(context); // Go back
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã rời khỏi nhóm'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: groupProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Rời nhóm'),
              );
            },
          ),
        ],
      ),
    );
  }
}
