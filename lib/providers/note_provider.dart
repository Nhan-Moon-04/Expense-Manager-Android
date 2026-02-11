import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<NoteModel> get notes => _notes;
  List<NoteModel> get pinnedNotes => _notes.where((n) => n.isPinned).toList();
  List<NoteModel> get unpinnedNotes =>
      _notes.where((n) => !n.isPinned).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to notes
  void listenToNotes(String userId) {
    _noteService.getUserNotes(userId).listen((notes) {
      _notes = notes;
      notifyListeners();
    });
  }

  // Add note
  Future<bool> addNote(NoteModel note) async {
    _setLoading(true);
    _clearError();

    try {
      NoteModel newNote = await _noteService.addNote(note);
      _notes.insert(0, newNote);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể thêm ghi chú.');
      _setLoading(false);
      return false;
    }
  }

  // Update note
  Future<bool> updateNote(NoteModel note) async {
    _setLoading(true);
    _clearError();

    try {
      await _noteService.updateNote(note);

      int index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể cập nhật ghi chú.');
      _setLoading(false);
      return false;
    }
  }

  // Delete note
  Future<bool> deleteNote(String noteId) async {
    _setLoading(true);
    _clearError();

    try {
      await _noteService.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Không thể xóa ghi chú.');
      _setLoading(false);
      return false;
    }
  }

  // Toggle pin
  Future<bool> togglePin(String noteId) async {
    try {
      int index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        bool newPinState = !_notes[index].isPinned;
        await _noteService.togglePin(noteId, newPinState);
        _notes[index] = _notes[index].copyWith(isPinned: newPinState);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Không thể ghim ghi chú.');
      return false;
    }
  }

  // Search notes
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    try {
      return await _noteService.searchNotes(userId, query);
    } catch (e) {
      _setError('Không thể tìm kiếm ghi chú.');
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
