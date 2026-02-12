import 'package:flutter/material.dart';
import '../services/admin_stats_service.dart';
import '../services/admin_user_service.dart';

class AdminStatsProvider extends ChangeNotifier {
  final AdminStatsService _statsService = AdminStatsService();
  final AdminUserService _userService = AdminUserService();

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard stats
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalGroups = 0;
  int _totalExpenses = 0;
  int _newUsersToday = 0;
  int _newUsersThisMonth = 0;
  Map<String, double> _overallIncomeExpense = {};

  // Detail stats
  Map<int, Map<String, double>> _dailyStats = {};
  Map<int, Map<String, double>> _monthlyStats = {};
  Map<int, Map<String, double>> _yearlyStats = {};
  Map<String, double> _categoryStats = {};
  List<Map<String, dynamic>> _topSpenders = [];
  Map<int, int> _newUsersDailyStats = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _totalUsers;
  int get activeUsers => _activeUsers;
  int get totalGroups => _totalGroups;
  int get totalExpenses => _totalExpenses;
  int get newUsersToday => _newUsersToday;
  int get newUsersThisMonth => _newUsersThisMonth;
  Map<String, double> get overallIncomeExpense => _overallIncomeExpense;
  Map<int, Map<String, double>> get dailyStats => _dailyStats;
  Map<int, Map<String, double>> get monthlyStats => _monthlyStats;
  Map<int, Map<String, double>> get yearlyStats => _yearlyStats;
  Map<String, double> get categoryStats => _categoryStats;
  List<Map<String, dynamic>> get topSpenders => _topSpenders;
  Map<int, int> get newUsersDailyStats => _newUsersDailyStats;

  /// Tải thống kê dashboard
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      DateTime now = DateTime.now();
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Chạy song song
      final results = await Future.wait([
        _userService.getTotalUsersCount(),
        _userService.getActiveUsersCount(),
        _statsService.getTotalGroupsCount(),
        _statsService.getTotalExpensesCount(),
        _userService.getNewUsers(startOfToday, endOfToday),
        _userService.getNewUsers(startOfMonth, endOfMonth),
        _statsService.getTotalIncomeExpense(startOfMonth, endOfMonth),
      ]);

      _totalUsers = results[0] as int;
      _activeUsers = results[1] as int;
      _totalGroups = results[2] as int;
      _totalExpenses = results[3] as int;
      _newUsersToday = (results[4] as List).length;
      _newUsersThisMonth = (results[5] as List).length;
      _overallIncomeExpense = results[6] as Map<String, double>;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải thống kê theo ngày
  Future<void> loadDailyStats(int year, int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      _dailyStats = await _statsService.getDailyStats(year, month);
      _newUsersDailyStats = await _statsService.getNewUsersDailyStats(
        year,
        month,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải thống kê theo tháng
  Future<void> loadMonthlyStats(int year) async {
    _isLoading = true;
    notifyListeners();

    try {
      _monthlyStats = await _statsService.getMonthlyStats(year);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải thống kê theo năm
  Future<void> loadYearlyStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _yearlyStats = await _statsService.getYearlyStats();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải thống kê theo danh mục
  Future<void> loadCategoryStats(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _categoryStats = await _statsService.getCategoryStats(startDate, endDate);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải top spenders
  Future<void> loadTopSpenders({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _topSpenders = await _statsService.getTopSpenders(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
