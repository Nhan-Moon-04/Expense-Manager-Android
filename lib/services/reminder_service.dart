import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reminders';

  // Add reminder
  Future<ReminderModel> addReminder(ReminderModel reminder) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(reminder.toFirestore());
      return reminder.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Update reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(reminder.id)
          .update(reminder.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get user reminders stream
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('reminderTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get active reminders
  Stream<List<ReminderModel>> getActiveReminders(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .where('isCompleted', isEqualTo: false)
        .orderBy('reminderTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get upcoming reminders (next 24 hours)
  Future<List<ReminderModel>> getUpcomingReminders(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime tomorrow = now.add(const Duration(hours: 24));

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .where(
            'reminderTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .where(
            'reminderTime',
            isLessThanOrEqualTo: Timestamp.fromDate(tomorrow),
          )
          .orderBy('reminderTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mark reminder as completed
  Future<void> markAsCompleted(String reminderId) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).update({
        'isCompleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Toggle reminder active status
  Future<void> toggleActive(String reminderId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get single reminder
  Future<ReminderModel?> getReminder(String reminderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(reminderId)
          .get();
      if (doc.exists) {
        return ReminderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
