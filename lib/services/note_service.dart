import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notes';

  // Add note
  Future<NoteModel> addNote(NoteModel note) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(note.toFirestore());
      return note.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Update note
  Future<void> updateNote(NoteModel note) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(note.id)
          .update(note.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection(_collection).doc(noteId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get user notes stream
  Stream<List<NoteModel>> getUserNotes(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList(),
        );
  }

  // Get single note
  Future<NoteModel?> getNote(String noteId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(noteId)
          .get();
      if (doc.exists) {
        return NoteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Toggle pin status
  Future<void> togglePin(String noteId, bool isPinned) async {
    try {
      await _firestore.collection(_collection).doc(noteId).update({
        'isPinned': isPinned,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Search notes
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      List<NoteModel> allNotes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();

      // Filter by query (search in title and content)
      String lowercaseQuery = query.toLowerCase();
      return allNotes.where((note) {
        return note.title.toLowerCase().contains(lowercaseQuery) ||
            note.content.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get notes by tag
  Future<List<NoteModel>> getNotesByTag(String userId, String tag) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('tags', arrayContains: tag)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
