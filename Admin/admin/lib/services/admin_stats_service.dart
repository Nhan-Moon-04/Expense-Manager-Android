import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== TỔNG QUAN ==========

  /// Lấy tổng số groups
  Future<int> getTotalGroupsCount() async {
    try {
      AggregateQuerySnapshot snapshot = await _firestore
          .collection('groups')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy tổng số expenses
  Future<int> getTotalExpensesCount() async {
    try {
      AggregateQuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy tổng số notifications
  Future<int> getTotalNotificationsCount() async {
    try {
      AggregateQuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  // ========== THỐNG KÊ CHI TIÊU ==========

  /// Lấy tất cả expenses trong khoảng thời gian (toàn hệ thống)
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Thống kê tổng thu/chi theo khoảng thời gian
  Future<Map<String, double>> getTotalIncomeExpense(
    DateTime startDate,
    DateTime endDate,
  ) async {
    List<ExpenseModel> expenses = await getExpensesByDateRange(
      startDate,
      endDate,
    );

    double totalIncome = 0;
    double totalExpense = 0;

    for (var e in expenses) {
      if (e.type == ExpenseType.income) {
        totalIncome += e.amount;
      } else {
        totalExpense += e.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  /// Thống kê theo ngày trong tháng
  Future<Map<int, Map<String, double>>> getDailyStats(
    int year,
    int month,
  ) async {
    DateTime startOfMonth = DateTime(year, month, 1);
    DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    List<ExpenseModel> expenses = await getExpensesByDateRange(
      startOfMonth,
      endOfMonth,
    );

    Map<int, Map<String, double>> dailyMap = {};

    for (var expense in expenses) {
      int day = expense.date.day;
      dailyMap.putIfAbsent(day, () => {'income': 0, 'expense': 0});

      if (expense.type == ExpenseType.income) {
        dailyMap[day]!['income'] =
            (dailyMap[day]!['income'] ?? 0) + expense.amount;
      } else {
        dailyMap[day]!['expense'] =
            (dailyMap[day]!['expense'] ?? 0) + expense.amount;
      }
    }

    return dailyMap;
  }

  /// Thống kê theo tháng trong năm
  Future<Map<int, Map<String, double>>> getMonthlyStats(int year) async {
    DateTime startOfYear = DateTime(year, 1, 1);
    DateTime endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    List<ExpenseModel> expenses = await getExpensesByDateRange(
      startOfYear,
      endOfYear,
    );

    Map<int, Map<String, double>> monthlyMap = {};

    for (int i = 1; i <= 12; i++) {
      monthlyMap[i] = {'income': 0, 'expense': 0};
    }

    for (var expense in expenses) {
      int month = expense.date.month;
      if (expense.type == ExpenseType.income) {
        monthlyMap[month]!['income'] =
            (monthlyMap[month]!['income'] ?? 0) + expense.amount;
      } else {
        monthlyMap[month]!['expense'] =
            (monthlyMap[month]!['expense'] ?? 0) + expense.amount;
      }
    }

    return monthlyMap;
  }

  /// Thống kê theo năm
  Future<Map<int, Map<String, double>>> getYearlyStats() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      Map<int, Map<String, double>> yearlyMap = {};

      for (var expense in expenses) {
        int year = expense.date.year;
        yearlyMap.putIfAbsent(year, () => {'income': 0, 'expense': 0});

        if (expense.type == ExpenseType.income) {
          yearlyMap[year]!['income'] =
              (yearlyMap[year]!['income'] ?? 0) + expense.amount;
        } else {
          yearlyMap[year]!['expense'] =
              (yearlyMap[year]!['expense'] ?? 0) + expense.amount;
        }
      }

      return yearlyMap;
    } catch (e) {
      rethrow;
    }
  }

  /// Thống kê theo danh mục
  Future<Map<String, double>> getCategoryStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    List<ExpenseModel> expenses = await getExpensesByDateRange(
      startDate,
      endDate,
    );

    Map<String, double> categoryMap = {};

    for (var expense in expenses) {
      if (expense.type == ExpenseType.expense) {
        String cat = expense.category.name;
        categoryMap[cat] = (categoryMap[cat] ?? 0) + expense.amount;
      }
    }

    return categoryMap;
  }

  /// Top users chi tiêu nhiều nhất
  Future<List<Map<String, dynamic>>> getTopSpenders({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    List<ExpenseModel> expenses;
    if (startDate != null && endDate != null) {
      expenses = await getExpensesByDateRange(startDate, endDate);
    } else {
      QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('type', isEqualTo: 'expense')
          .get();
      expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    }

    // Group by userId
    Map<String, double> userExpenses = {};
    for (var expense in expenses) {
      if (expense.type == ExpenseType.expense) {
        userExpenses[expense.userId] =
            (userExpenses[expense.userId] ?? 0) + expense.amount;
      }
    }

    // Sort và lấy top
    var sorted = userExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> result = [];
    for (var entry in sorted.take(limit)) {
      // Lấy thông tin user
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(entry.key)
          .get();
      String userName = 'Unknown';
      if (userDoc.exists) {
        userName =
            (userDoc.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown';
      }

      result.add({
        'userId': entry.key,
        'userName': userName,
        'totalExpense': entry.value,
      });
    }

    return result;
  }

  /// Thống kê users mới theo ngày trong tháng
  Future<Map<int, int>> getNewUsersDailyStats(int year, int month) async {
    DateTime startOfMonth = DateTime(year, month, 1);
    DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    Map<int, int> dailyMap = {};
    for (var doc in snapshot.docs) {
      UserModel user = UserModel.fromFirestore(doc);
      int day = user.createdAt.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + 1;
    }

    return dailyMap;
  }

  /// Lấy danh sách groups
  Future<List<GroupModel>> getAllGroups() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
