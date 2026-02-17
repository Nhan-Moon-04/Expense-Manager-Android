import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _todayExpenses = [];
  List<ExpenseModel> _monthExpenses = [];
  List<ExpenseModel> _previousMonthExpenses = [];
  Map<ExpenseCategory, double> _categoryExpenses = {};
  Map<int, Map<String, double>> _dailySummary = {};
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get todayExpenses => _todayExpenses;
  List<ExpenseModel> get monthExpenses => _monthExpenses;
  List<ExpenseModel> get previousMonthExpenses => _previousMonthExpenses;
  Map<ExpenseCategory, double> get categoryExpenses => _categoryExpenses;
  Map<int, Map<String, double>> get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get todayTotal {
    return _todayExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthTotal {
    return _monthExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get monthIncome {
    return _monthExpenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0, (sum, e) => sum + e.amount);
  }

  /// Total balance of all time (all income - all expense)
  double get totalBalance {
    final totalIncome = _expenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalExpense = _expenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
    return totalIncome - totalExpense;
  }

  /// Net balance of this month (income - expense)
  double get monthNet => monthIncome - monthTotal;

  /// Net balance of previous month (income - expense)
  double get previousMonthNet {
    final prevIncome = _previousMonthExpenses
        .where((e) => e.type == ExpenseType.income)
        .fold(0.0, (sum, e) => sum + e.amount);
    final prevExpense = _previousMonthExpenses
        .where((e) => e.type == ExpenseType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);
    return prevIncome - prevExpense;
  }

  /// Growth percentage compared to previous month
  /// Positive = improving (more net income), Negative = declining
  double get monthGrowthPercent {
    if (previousMonthNet == 0) {
      return monthNet > 0 ? 100 : (monthNet < 0 ? -100 : 0);
    }
    return ((monthNet - previousMonthNet) / previousMonthNet.abs()) * 100;
  }

  // Listen to expenses
  void listenToExpenses(String userId) {
    _expenseService.getUserExpenses(userId).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  // Load today's expenses
  Future<void> loadTodayExpenses(String userId) async {
    _setLoading(true);
    try {
      _todayExpenses = await _expenseService.getTodayExpenses(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải chi tiêu hôm nay.');
      _setLoading(false);
    }
  }

  // Load month's expenses
  Future<void> loadMonthExpenses(String userId) async {
    _setLoading(true);
    try {
      _monthExpenses = await _expenseService.getMonthExpenses(userId);
      // Also load previous month for growth comparison
      await _loadPreviousMonthExpenses(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải chi tiêu tháng này.');
      _setLoading(false);
    }
  }

  // Load previous month's expenses for growth comparison
  Future<void> _loadPreviousMonthExpenses(String userId) async {
    try {
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final endOfPrevMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
      _previousMonthExpenses = await _expenseService.getExpensesByDateRange(
        userId,
        prevMonth,
        endOfPrevMonth,
      );
    } catch (e) {
      _previousMonthExpenses = [];
    }
  }

  // Load expenses by category
  Future<void> loadCategoryExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _setLoading(true);
    try {
      _categoryExpenses = await _expenseService.getExpensesByCategory(
        userId,
        startDate,
        endDate,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải chi tiêu theo danh mục.');
      _setLoading(false);
    }
  }

  // Load daily summary
  Future<void> loadDailySummary(String userId, int year, int month) async {
    _setLoading(true);
    try {
      _dailySummary = await _expenseService.getDailySummary(
        userId,
        year,
        month,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải tóm tắt hàng ngày.');
      _setLoading(false);
    }
  }

  // Add expense
  Future<bool> addExpense(ExpenseModel expense) async {
    _setLoading(true);
    _clearError();

    try {
      ExpenseModel newExpense = await _expenseService.addExpense(expense);

      // Don't insert into _expenses here — the Firestore stream listener
      // (listenToExpenses) already handles that automatically.
      // Only update _todayExpenses and _monthExpenses which have no stream.
      DateTime now = DateTime.now();
      if (expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day) {
        _todayExpenses.insert(0, newExpense);
      }
      if (expense.date.year == now.year && expense.date.month == now.month) {
        _monthExpenses.insert(0, newExpense);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể thêm chi tiêu.');
      _setLoading(false);
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense(ExpenseModel expense) async {
    _setLoading(true);
    _clearError();

    try {
      await _expenseService.updateExpense(expense);

      int index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể cập nhật chi tiêu.');
      _setLoading(false);
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    _setLoading(true);
    _clearError();

    try {
      await _expenseService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      _todayExpenses.removeWhere((e) => e.id == expenseId);
      _monthExpenses.removeWhere((e) => e.id == expenseId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể xóa chi tiêu.');
      _setLoading(false);
      return false;
    }
  }

  // Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _expenseService.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _setError('Không thể tải chi tiêu.');
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear all local data (used when user deletes all data)
  void clearAllData() {
    _expenses.clear();
    _todayExpenses.clear();
    _monthExpenses.clear();
    _previousMonthExpenses.clear();
    _categoryExpenses.clear();
    _dailySummary.clear();
    notifyListeners();
  }
}
