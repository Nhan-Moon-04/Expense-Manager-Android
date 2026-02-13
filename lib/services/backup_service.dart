import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense_model.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Backup all user data to a Firestore document in 'backups' collection
  Future<void> backupToCloud(String userId) async {
    // Fetch all expenses
    final expensesSnap = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    final expenses = expensesSnap.docs.map((doc) {
      final data = doc.data();
      data['_docId'] = doc.id;
      return data;
    }).toList();

    // Fetch all notes
    final notesSnap = await _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .get();

    final notes = notesSnap.docs.map((doc) {
      final data = doc.data();
      data['_docId'] = doc.id;
      return data;
    }).toList();

    // Fetch all reminders
    final remindersSnap = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    final reminders = remindersSnap.docs.map((doc) {
      final data = doc.data();
      data['_docId'] = doc.id;
      return data;
    }).toList();

    // Fetch user document
    final userDoc = await _firestore.collection('users').doc(userId).get();

    // Save backup
    await _firestore.collection('backups').doc(userId).set({
      'user': userDoc.data(),
      'expenses': expenses,
      'notes': notes,
      'reminders': reminders,
      'backupAt': FieldValue.serverTimestamp(),
      'expenseCount': expenses.length,
      'noteCount': notes.length,
      'reminderCount': reminders.length,
    });
  }

  /// Restore data from cloud backup
  Future<Map<String, int>> restoreFromCloud(String userId) async {
    final backupDoc = await _firestore.collection('backups').doc(userId).get();

    if (!backupDoc.exists) {
      throw Exception('Không tìm thấy bản sao lưu');
    }

    final data = backupDoc.data()!;
    final batch = _firestore.batch();
    int restoredExpenses = 0;
    int restoredNotes = 0;
    int restoredReminders = 0;

    // Restore expenses
    final expenses = (data['expenses'] as List<dynamic>?) ?? [];
    for (final expense in expenses) {
      final map = Map<String, dynamic>.from(expense as Map);
      final docId = map.remove('_docId') as String?;
      if (docId != null) {
        batch.set(
          _firestore.collection('expenses').doc(docId),
          map,
          SetOptions(merge: true),
        );
        restoredExpenses++;
      }
    }

    // Restore notes
    final notes = (data['notes'] as List<dynamic>?) ?? [];
    for (final note in notes) {
      final map = Map<String, dynamic>.from(note as Map);
      final docId = map.remove('_docId') as String?;
      if (docId != null) {
        batch.set(
          _firestore.collection('notes').doc(docId),
          map,
          SetOptions(merge: true),
        );
        restoredNotes++;
      }
    }

    // Restore reminders
    final reminders = (data['reminders'] as List<dynamic>?) ?? [];
    for (final reminder in reminders) {
      final map = Map<String, dynamic>.from(reminder as Map);
      final docId = map.remove('_docId') as String?;
      if (docId != null) {
        batch.set(
          _firestore.collection('reminders').doc(docId),
          map,
          SetOptions(merge: true),
        );
        restoredReminders++;
      }
    }

    await batch.commit();

    return {
      'expenses': restoredExpenses,
      'notes': restoredNotes,
      'reminders': restoredReminders,
    };
  }

  /// Check if backup exists and return info
  Future<Map<String, dynamic>?> getBackupInfo(String userId) async {
    final doc = await _firestore.collection('backups').doc(userId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return {
      'backupAt': (data['backupAt'] as Timestamp?)?.toDate(),
      'expenseCount': data['expenseCount'] ?? 0,
      'noteCount': data['noteCount'] ?? 0,
      'reminderCount': data['reminderCount'] ?? 0,
    };
  }

  /// Export expenses to CSV file and return file path
  Future<String> exportToExcel(
    String userId,
    NumberFormat currencyFormat,
  ) async {
    final expensesSnap = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    final expenses = expensesSnap.docs
        .map((doc) => ExpenseModel.fromFirestore(doc))
        .toList();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final csvBuffer = StringBuffer();

    // BOM for UTF-8 Excel compatibility
    csvBuffer.write('\uFEFF');

    // Header
    csvBuffer.writeln('Ngày,Loại,Danh mục,Số tiền,Mô tả,Tự động');

    // Rows
    for (final expense in expenses) {
      final type = expense.type == ExpenseType.income ? 'Thu nhập' : 'Chi tiêu';
      final category = _getCategoryName(expense.category);
      final amount = currencyFormat.format(expense.amount);
      final description =
          '"${(expense.description ?? '').replaceAll('"', '""')}"';
      final auto = expense.isAutoAdded ? 'Có' : 'Không';
      final date = dateFormat.format(expense.date);

      csvBuffer.writeln('$date,$type,$category,$amount,$description,$auto');
    }

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvBuffer.toString());

    return file.path;
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.bills:
        return 'Hóa đơn';
      case ExpenseCategory.health:
        return 'Sức khỏe';
      case ExpenseCategory.education:
        return 'Giáo dục';
      case ExpenseCategory.salary:
        return 'Lương';
      case ExpenseCategory.bonus:
        return 'Thưởng';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }
}
