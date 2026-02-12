import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/note_provider.dart';
import '../../models/note_model.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<NoteModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Delay load to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      Provider.of<NoteProvider>(
        context,
        listen: false,
      ).listenToNotes(authProvider.user!.uid);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    setState(() => _isSearching = true);
    _searchResults = await noteProvider.searchNotes(
      authProvider.user!.uid,
      query,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.notes),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ghi chú...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Notes list
          Expanded(child: _buildNotesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotesList() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final notes = _isSearching ? _searchResults : noteProvider.notes;

        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  _isSearching
                      ? 'Không tìm thấy ghi chú'
                      : 'Chưa có ghi chú nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final pinnedNotes = notes.where((n) => n.isPinned).toList();
        final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pinnedNotes.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đã ghim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildNotesGrid(pinnedNotes),
              const SizedBox(height: 16),
            ],
            if (unpinnedNotes.isNotEmpty) ...[
              if (pinnedNotes.isNotEmpty)
                Text(
                  'Khác',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (pinnedNotes.isNotEmpty) const SizedBox(height: 8),
              _buildNotesGrid(unpinnedNotes),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNotesGrid(List<NoteModel> notes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(notes[index]);
      },
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    final noteColor = note.color != null
        ? Color(int.parse(note.color!.replaceFirst('#', '0xFF')))
        : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddNoteScreen(note: note)),
        );
      },
      onLongPress: () => _showNoteOptions(note),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isPinned)
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(note.updatedAt),
              style: TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteOptions(NoteModel note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: AppColors.primary,
                ),
                title: Text(note.isPinned ? 'Bỏ ghim' : 'Ghim'),
                onTap: () async {
                  Navigator.pop(context);
                  await Provider.of<NoteProvider>(
                    context,
                    listen: false,
                  ).togglePin(note.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Sửa'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNoteScreen(note: note),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Xóa', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(note);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<NoteProvider>(
                context,
                listen: false,
              ).deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
