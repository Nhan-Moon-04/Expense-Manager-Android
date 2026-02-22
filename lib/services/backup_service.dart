import 'dart:convert';
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

    // Fetch all groups (owned by or member of)
    final groupsSnap = await _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .get();

    final groups = groupsSnap.docs
        .where((doc) {
          final members = (doc.data()['members'] as List<dynamic>?) ?? [];
          return members.any((m) => (m as Map)['userId'] == userId);
        })
        .map((doc) {
          final data = doc.data();
          data['_docId'] = doc.id;
          return data;
        })
        .toList();

    // Fetch user document
    final userDoc = await _firestore.collection('users').doc(userId).get();

    // Save backup
    await _firestore.collection('backups').doc(userId).set({
      'user': userDoc.data(),
      'expenses': expenses,
      'notes': notes,
      'reminders': reminders,
      'groups': groups,
      'backupAt': FieldValue.serverTimestamp(),
      'expenseCount': expenses.length,
      'noteCount': notes.length,
      'reminderCount': reminders.length,
      'groupCount': groups.length,
    });
  }

  /// Helper to write docs in batches of 400 (Firestore limit: 500)
  Future<void> _batchSet(
    List<dynamic> items,
    String collection,
    _Counter counter,
  ) async {
    for (var i = 0; i < items.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < items.length) ? i + 400 : items.length;
      for (var j = i; j < end; j++) {
        final map = Map<String, dynamic>.from(items[j] as Map);
        final docId = map.remove('_docId') as String?;
        if (docId != null) {
          batch.set(
            _firestore.collection(collection).doc(docId),
            map,
            SetOptions(merge: true),
          );
          counter.value++;
        }
      }
      await batch.commit();
    }
  }

  /// Restore all data from cloud backup
  Future<Map<String, int>> restoreFromCloud(String userId) async {
    final backupDoc = await _firestore.collection('backups').doc(userId).get();

    if (!backupDoc.exists) {
      throw Exception('Không tìm thấy bản sao lưu');
    }

    final data = backupDoc.data()!;
    final restoredExpenses = _Counter();
    final restoredNotes = _Counter();
    final restoredReminders = _Counter();
    final restoredGroups = _Counter();

    // Restore expenses
    await _batchSet(
      (data['expenses'] as List<dynamic>?) ?? [],
      'expenses',
      restoredExpenses,
    );

    // Restore notes
    await _batchSet(
      (data['notes'] as List<dynamic>?) ?? [],
      'notes',
      restoredNotes,
    );

    // Restore reminders
    await _batchSet(
      (data['reminders'] as List<dynamic>?) ?? [],
      'reminders',
      restoredReminders,
    );

    // Restore groups
    await _batchSet(
      (data['groups'] as List<dynamic>?) ?? [],
      'groups',
      restoredGroups,
    );

    // Restore user document (merge to keep login info)
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
    }

    return {
      'expenses': restoredExpenses.value,
      'notes': restoredNotes.value,
      'reminders': restoredReminders.value,
      'groups': restoredGroups.value,
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
      'groupCount': data['groupCount'] ?? 0,
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

  /// Backup all user data to a local JSON file and return file path
  Future<String> backupToLocalFile(String userId) async {
    // Fetch all expenses
    final expensesSnap = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    final expenses = expensesSnap.docs.map((doc) {
      final data = doc.data();
      data['_docId'] = doc.id;
      // Convert Timestamps to ISO strings for JSON serialization
      data.forEach((key, value) {
        if (value is Timestamp) {
          data[key] = value.toDate().toIso8601String();
        }
      });
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
      data.forEach((key, value) {
        if (value is Timestamp) {
          data[key] = value.toDate().toIso8601String();
        }
      });
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
      data.forEach((key, value) {
        if (value is Timestamp) {
          data[key] = value.toDate().toIso8601String();
        }
      });
      return data;
    }).toList();

    // Fetch all groups (owned by or member of)
    final groupsSnap = await _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .get();

    final groups = groupsSnap.docs
        .where((doc) {
          final members = (doc.data()['members'] as List<dynamic>?) ?? [];
          return members.any((m) => (m as Map)['userId'] == userId);
        })
        .map((doc) {
          final data = doc.data();
          data['_docId'] = doc.id;
          // Convert Timestamps in top-level fields
          data.forEach((key, value) {
            if (value is Timestamp) {
              data[key] = value.toDate().toIso8601String();
            }
          });
          // Convert Timestamps in members list
          if (data['members'] != null) {
            data['members'] = (data['members'] as List).map((m) {
              final member = Map<String, dynamic>.from(m as Map);
              member.forEach((key, value) {
                if (value is Timestamp) {
                  member[key] = value.toDate().toIso8601String();
                }
              });
              return member;
            }).toList();
          }
          return data;
        })
        .toList();

    // Fetch user document
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData != null) {
      userData.forEach((key, value) {
        if (value is Timestamp) {
          userData[key] = value.toDate().toIso8601String();
        }
      });
    }

    final backupData = {
      'userId': userId,
      'backupAt': DateTime.now().toIso8601String(),
      'user': userData,
      'expenses': expenses,
      'notes': notes,
      'reminders': reminders,
      'groups': groups,
      'expenseCount': expenses.length,
      'noteCount': notes.length,
      'reminderCount': reminders.length,
      'groupCount': groups.length,
    };

    // Save to local file
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backupData),
    );

    return file.path;
  }

  /// Delete all user data from Firestore (keeps user document for login)
  Future<Map<String, int>> deleteAllUserData(String userId) async {
    int deletedExpenses = 0;
    int deletedNotes = 0;
    int deletedReminders = 0;
    int deletedGroups = 0;

    // Delete expenses in batches (Firestore limit: 500 per batch)
    final expensesSnap = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    for (var i = 0; i < expensesSnap.docs.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < expensesSnap.docs.length)
          ? i + 400
          : expensesSnap.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(expensesSnap.docs[j].reference);
        deletedExpenses++;
      }
      await batch.commit();
    }

    // Delete notes
    final notesSnap = await _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .get();

    for (var i = 0; i < notesSnap.docs.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < notesSnap.docs.length)
          ? i + 400
          : notesSnap.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(notesSnap.docs[j].reference);
        deletedNotes++;
      }
      await batch.commit();
    }

    // Delete reminders
    final remindersSnap = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .get();

    for (var i = 0; i < remindersSnap.docs.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < remindersSnap.docs.length)
          ? i + 400
          : remindersSnap.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(remindersSnap.docs[j].reference);
        deletedReminders++;
      }
      await batch.commit();
    }

    // Delete notifications
    final notificationsSnap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var i = 0; i < notificationsSnap.docs.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < notificationsSnap.docs.length)
          ? i + 400
          : notificationsSnap.docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(notificationsSnap.docs[j].reference);
      }
      await batch.commit();
    }

    // Delete/leave groups
    final groupsSnap = await _firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in groupsSnap.docs) {
      final data = doc.data();
      final members = (data['members'] as List<dynamic>?) ?? [];
      final isMember = members.any((m) => (m as Map)['userId'] == userId);
      if (!isMember) continue;

      if (data['ownerId'] == userId) {
        // User owns this group → hard delete
        await doc.reference.delete();
        deletedGroups++;

        // Also delete all expenses belonging to this group
        final groupExpensesSnap = await _firestore
            .collection('expenses')
            .where('groupId', isEqualTo: doc.id)
            .get();

        for (var i = 0; i < groupExpensesSnap.docs.length; i += 400) {
          final batch = _firestore.batch();
          final end = (i + 400 < groupExpensesSnap.docs.length)
              ? i + 400
              : groupExpensesSnap.docs.length;
          for (var j = i; j < end; j++) {
            batch.delete(groupExpensesSnap.docs[j].reference);
          }
          await batch.commit();
        }
      } else {
        // User is a member → remove from group
        final updatedMembers = members
            .where((m) => (m as Map)['userId'] != userId)
            .toList();
        await doc.reference.update({
          'members': updatedMembers,
          'updatedAt': Timestamp.now(),
        });
        deletedGroups++;
      }
    }

    // Reset user balance to 0 (keep user document for login)
    await _firestore.collection('users').doc(userId).update({
      'totalBalance': 0,
      'updatedAt': Timestamp.now(),
    });

    return {
      'expenses': deletedExpenses,
      'notes': deletedNotes,
      'reminders': deletedReminders,
      'groups': deletedGroups,
    };
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

class _Counter {
  int value = 0;
}
