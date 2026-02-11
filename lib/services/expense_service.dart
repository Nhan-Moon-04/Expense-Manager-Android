import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'expenses';

  // Add expense
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(expense.toFirestore());
      return expense.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(expense.id)
          .update(expense.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection(_collection).doc(expenseId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get user expenses stream
  Stream<List<ExpenseModel>> getUserExpenses(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('groupId', isNull: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('groupId', isNull: true)
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

  // Get today's expenses
  Future<List<ExpenseModel>> getTodayExpenses(String userId) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getExpensesByDateRange(userId, startOfDay, endOfDay);
  }

  // Get this month's expenses
  Future<List<ExpenseModel>> getMonthExpenses(String userId) async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getExpensesByDateRange(userId, startOfMonth, endOfMonth);
  }

  // Get expenses by category
  Future<Map<ExpenseCategory, double>> getExpensesByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      List<ExpenseModel> expenses = await getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );

      Map<ExpenseCategory, double> categoryMap = {};
      for (var expense in expenses) {
        if (expense.type == ExpenseType.expense) {
          categoryMap[expense.category] =
              (categoryMap[expense.category] ?? 0) + expense.amount;
        }
      }

      return categoryMap;
    } catch (e) {
      rethrow;
    }
  }

  // Get total income
  Future<double> getTotalIncome(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('groupId', isNull: true)
          .where('type', isEqualTo: ExpenseType.income.name)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        ExpenseModel expense = ExpenseModel.fromFirestore(doc);
        total += expense.amount;
      }

      return total;
    } catch (e) {
      rethrow;
    }
  }

  // Get total expense
  Future<double> getTotalExpense(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('groupId', isNull: true)
          .where('type', isEqualTo: ExpenseType.expense.name)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        ExpenseModel expense = ExpenseModel.fromFirestore(doc);
        total += expense.amount;
      }

      return total;
    } catch (e) {
      rethrow;
    }
  }

  // Get group expenses
  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get daily summary for a month
  Future<Map<int, Map<String, double>>> getDailySummary(
    String userId,
    int year,
    int month,
  ) async {
    DateTime startOfMonth = DateTime(year, month, 1);
    DateTime endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    List<ExpenseModel> expenses = await getExpensesByDateRange(
      userId,
      startOfMonth,
      endOfMonth,
    );

    Map<int, Map<String, double>> dailyMap = {};

    for (var expense in expenses) {
      int day = expense.date.day;
      if (dailyMap[day] == null) {
        dailyMap[day] = {'income': 0, 'expense': 0};
      }

      if (expense.type == ExpenseType.income) {
        dailyMap[day]!['income'] = dailyMap[day]!['income']! + expense.amount;
      } else {
        dailyMap[day]!['expense'] = dailyMap[day]!['expense']! + expense.amount;
      }
    }

    return dailyMap;
  }
}
