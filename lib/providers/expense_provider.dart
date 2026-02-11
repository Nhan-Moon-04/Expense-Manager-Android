import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _todayExpenses = [];
  List<ExpenseModel> _monthExpenses = [];
  Map<ExpenseCategory, double> _categoryExpenses = {};
  Map<int, Map<String, double>> _dailySummary = {};
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get todayExpenses => _todayExpenses;
  List<ExpenseModel> get monthExpenses => _monthExpenses;
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
      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải chi tiêu tháng này.');
      _setLoading(false);
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
      _expenses.insert(0, newExpense);

      // Update today/month expenses if applicable
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
}
