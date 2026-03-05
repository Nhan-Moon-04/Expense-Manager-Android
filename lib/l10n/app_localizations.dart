class AppLocalizations {
  static String _currentLanguage = 'vi';

  static void setLanguage(String language) {
    _currentLanguage = language;
  }

  static String get currentLanguage => _currentLanguage;

  static String get(String key) {
    final map = _currentLanguage == 'en' ? _en : _vi;
    return map[key] ?? _vi[key] ?? key;
  }

  static const Map<String, String> _vi = {
    // App Info
    'appName': 'Quản Lý Chi Tiêu',
    'appVersion': '1.0.0',
    'appDescription': 'Quản lý tài chính cá nhân thông minh',

    // Auth
    'login': 'Đăng Nhập',
    'register': 'Đăng Ký',
    'logout': 'Đăng Xuất',
    'email': 'Email',
    'password': 'Mật Khẩu',
    'confirmPassword': 'Xác Nhận Mật Khẩu',
    'fullName': 'Họ và Tên',
    'phone': 'Số Điện Thoại',
    'forgotPassword': 'Quên Mật Khẩu?',
    'dontHaveAccount': 'Chưa có tài khoản?',
    'alreadyHaveAccount': 'Đã có tài khoản?',
    'resetPassword': 'Đặt Lại Mật Khẩu',

    // Navigation
    'home': 'Trang Chủ',
    'expenses': 'Chi Tiêu',
    'notes': 'Ghi Chú',
    'groups': 'Nhóm',
    'profile': 'Tôi',

    // Expense
    'addExpense': 'Thêm Chi Tiêu',
    'editExpense': 'Sửa Chi Tiêu',
    'deleteExpense': 'Xóa Chi Tiêu',
    'amount': 'Số Tiền',
    'category': 'Danh Mục',
    'date': 'Ngày',
    'description': 'Mô Tả',
    'income': 'Thu Nhập',
    'expense': 'Chi Tiêu',
    'totalBalance': 'Tổng Số Dư',
    'todayExpense': 'Chi Tiêu Hôm Nay',
    'monthlyExpense': 'Chi Tiêu Tháng Này',

    // Categories
    'food': 'Ăn Uống',
    'transport': 'Di Chuyển',
    'shopping': 'Mua Sắm',
    'entertainment': 'Giải Trí',
    'bills': 'Hóa Đơn',
    'health': 'Sức Khỏe',
    'education': 'Giáo Dục',
    'other': 'Khác',

    // Notes
    'addNote': 'Thêm Ghi Chú',
    'editNote': 'Sửa Ghi Chú',
    'deleteNote': 'Xóa Ghi Chú',
    'noteTitle': 'Tiêu Đề',
    'noteContent': 'Nội Dung',

    // Groups
    'createGroup': 'Tạo Nhóm',
    'joinGroup': 'Tham Gia Nhóm',
    'leaveGroup': 'Rời Nhóm',
    'groupName': 'Tên Nhóm',
    'groupMembers': 'Thành Viên',
    'addMember': 'Thêm Thành Viên',
    'sharedExpenses': 'Chi Tiêu Chung',
    'splitBill': 'Chia Tiền',
    'groupCode': 'Mã Nhóm',

    // Reminders
    'reminders': 'Nhắc Nhở',
    'addReminder': 'Thêm Nhắc Nhở',
    'editReminder': 'Sửa Nhắc Nhở',
    'deleteReminder': 'Xóa Nhắc Nhở',
    'reminderTitle': 'Tiêu Đề',
    'reminderTime': 'Thời Gian',
    'reminderRepeat': 'Lặp Lại',

    // Profile
    'editProfile': 'Chỉnh Sửa Thông Tin',
    'settings': 'Cài Đặt',
    'notifications': 'Thông Báo',
    'changePassword': 'Đổi Mật Khẩu',
    'language': 'Ngôn Ngữ',
    'currency': 'Tiền Tệ',
    'about': 'Về Ứng Dụng',
    'theme': 'Giao diện',

    // Actions
    'save': 'Lưu',
    'cancel': 'Hủy',
    'delete': 'Xóa',
    'edit': 'Sửa',
    'add': 'Thêm',
    'confirm': 'Xác Nhận',
    'search': 'Tìm Kiếm',
    'filter': 'Lọc',
    'sort': 'Sắp Xếp',

    // Messages
    'loading': 'Đang Tải...',
    'success': 'Thành Công',
    'error': 'Lỗi',
    'noData': 'Không Có Dữ Liệu',
    'confirmDelete': 'Bạn có chắc muốn xóa?',
    'loginSuccess': 'Đăng nhập thành công',
    'registerSuccess': 'Đăng ký thành công',
    'logoutSuccess': 'Đăng xuất thành công',
    'saveSuccess': 'Lưu thành công',
    'deleteSuccess': 'Xóa thành công',
    'invalidEmail': 'Email không hợp lệ',
    'invalidPassword': 'Mật khẩu phải có ít nhất 6 ký tự',
    'passwordNotMatch': 'Mật khẩu không khớp',
    'requiredField': 'Trường này bắt buộc',

    // Wallet
    'wallets': 'Ví',
    'walletManagement': 'Quản lý Ví',
    'primaryWallet': 'Ví chính',
    'allWallets': 'Tất cả ví',
    'createWallet': 'Tạo ví mới',
    'walletName': 'Tên ví',
    'linkedBanks': 'Ngân hàng liên kết',
    'walletBalance': 'Số dư ví',

    // Dashboard
    'quickActions': 'Thao tác nhanh',
    'recentTransactions': 'Giao dịch gần đây',
    'viewAll': 'Xem tất cả',
    'thisMonth': 'Tháng này',
    'comparedToLastMonth': 'So với tháng trước',

    // Statistics
    'statistics': 'Thống kê',
    'monthlyOverview': 'Tổng quan tháng',
    'categoryBreakdown': 'Phân loại chi tiêu',
    'incomeVsExpense': 'Thu nhập vs Chi tiêu',
    'trend': 'Xu hướng',

    // Settings sections
    'account': 'Tài khoản',
    'display': 'Hiển thị',
    'autoExpense': 'Chi tiêu tự động',
    'data': 'Dữ liệu',
    'dangerZone': 'Vùng nguy hiểm',
    'backup': 'Sao lưu toàn bộ',
    'restore': 'Khôi phục toàn bộ',
    'exportReport': 'Xuất báo cáo',
    'deleteAllData': 'Xóa tất cả dữ liệu',

    // Theme
    'lightTheme': 'Sáng',
    'darkTheme': 'Tối',
    'systemTheme': 'Theo hệ thống',
    'chooseTheme': 'Chọn giao diện',
  };

  static const Map<String, String> _en = {
    // App Info
    'appName': 'Expense Manager',
    'appVersion': '1.0.0',
    'appDescription': 'Smart personal finance management',

    // Auth
    'login': 'Login',
    'register': 'Register',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'fullName': 'Full Name',
    'phone': 'Phone Number',
    'forgotPassword': 'Forgot Password?',
    'dontHaveAccount': "Don't have an account?",
    'alreadyHaveAccount': 'Already have an account?',
    'resetPassword': 'Reset Password',

    // Navigation
    'home': 'Home',
    'expenses': 'Expenses',
    'notes': 'Notes',
    'groups': 'Groups',
    'profile': 'Me',

    // Expense
    'addExpense': 'Add Expense',
    'editExpense': 'Edit Expense',
    'deleteExpense': 'Delete Expense',
    'amount': 'Amount',
    'category': 'Category',
    'date': 'Date',
    'description': 'Description',
    'income': 'Income',
    'expense': 'Expense',
    'totalBalance': 'Total Balance',
    'todayExpense': "Today's Expense",
    'monthlyExpense': "This Month's Expense",

    // Categories
    'food': 'Food & Drink',
    'transport': 'Transport',
    'shopping': 'Shopping',
    'entertainment': 'Entertainment',
    'bills': 'Bills',
    'health': 'Health',
    'education': 'Education',
    'other': 'Other',

    // Notes
    'addNote': 'Add Note',
    'editNote': 'Edit Note',
    'deleteNote': 'Delete Note',
    'noteTitle': 'Title',
    'noteContent': 'Content',

    // Groups
    'createGroup': 'Create Group',
    'joinGroup': 'Join Group',
    'leaveGroup': 'Leave Group',
    'groupName': 'Group Name',
    'groupMembers': 'Members',
    'addMember': 'Add Member',
    'sharedExpenses': 'Shared Expenses',
    'splitBill': 'Split Bill',
    'groupCode': 'Group Code',

    // Reminders
    'reminders': 'Reminders',
    'addReminder': 'Add Reminder',
    'editReminder': 'Edit Reminder',
    'deleteReminder': 'Delete Reminder',
    'reminderTitle': 'Title',
    'reminderTime': 'Time',
    'reminderRepeat': 'Repeat',

    // Profile
    'editProfile': 'Edit Profile',
    'settings': 'Settings',
    'notifications': 'Notifications',
    'changePassword': 'Change Password',
    'language': 'Language',
    'currency': 'Currency',
    'about': 'About',
    'theme': 'Theme',

    // Actions
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'confirm': 'Confirm',
    'search': 'Search',
    'filter': 'Filter',
    'sort': 'Sort',

    // Messages
    'loading': 'Loading...',
    'success': 'Success',
    'error': 'Error',
    'noData': 'No Data',
    'confirmDelete': 'Are you sure you want to delete?',
    'loginSuccess': 'Login successful',
    'registerSuccess': 'Registration successful',
    'logoutSuccess': 'Logout successful',
    'saveSuccess': 'Saved successfully',
    'deleteSuccess': 'Deleted successfully',
    'invalidEmail': 'Invalid email',
    'invalidPassword': 'Password must be at least 6 characters',
    'passwordNotMatch': 'Passwords do not match',
    'requiredField': 'This field is required',

    // Wallet
    'wallets': 'Wallets',
    'walletManagement': 'Wallet Management',
    'primaryWallet': 'Primary Wallet',
    'allWallets': 'All Wallets',
    'createWallet': 'Create Wallet',
    'walletName': 'Wallet Name',
    'linkedBanks': 'Linked Banks',
    'walletBalance': 'Wallet Balance',

    // Dashboard
    'quickActions': 'Quick Actions',
    'recentTransactions': 'Recent Transactions',
    'viewAll': 'View All',
    'thisMonth': 'This Month',
    'comparedToLastMonth': 'Compared to last month',

    // Statistics
    'statistics': 'Statistics',
    'monthlyOverview': 'Monthly Overview',
    'categoryBreakdown': 'Category Breakdown',
    'incomeVsExpense': 'Income vs Expense',
    'trend': 'Trend',

    // Settings sections
    'account': 'Account',
    'display': 'Display',
    'autoExpense': 'Auto Expense',
    'data': 'Data',
    'dangerZone': 'Danger Zone',
    'backup': 'Backup All',
    'restore': 'Restore All',
    'exportReport': 'Export Report',
    'deleteAllData': 'Delete All Data',

    // Theme
    'lightTheme': 'Light',
    'darkTheme': 'Dark',
    'systemTheme': 'System',
    'chooseTheme': 'Choose Theme',
  };
}
