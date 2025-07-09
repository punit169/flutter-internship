import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/note.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const QuickNotesApp());

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickNotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notes') ?? [];
    final loadedNotes = data.map((e) => Note.fromJson(json.decode(e))).toList();
    setState(() {
      _notes = loadedNotes;
      _filteredNotes = loadedNotes;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notes.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList('notes', data);
  }

  void _addNote(String title, String content) {
    final newNote = Note(title: title, content: content, date: DateTime.now());
    setState(() {
      _notes.add(newNote);
      _filteredNotes = List.from(_notes);
    });
    _saveNotes();
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
      _filteredNotes = List.from(_notes);
    });
    _saveNotes();
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes
          .where((note) =>
      note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query))
          .toList();
    });
  }

  void _shareNote(Note note) {
    final String textToShare = '${note.title}\n\n${note.content}';
    Share.share(textToShare, subject: 'Note: ${note.title}');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNoteDetailDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(note.title.isEmpty ? '(No Title)' : note.title),
          content: SingleChildScrollView(
            child: Text(note.content.isEmpty ? '(No Content)' : note.content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addNote(titleCtrl.text, contentCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(Note note) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                note.title = titleCtrl.text;
                note.content = contentCtrl.text;
              });
              _saveNotes();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(note);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Search Notes"),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter keyword...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _filterNotes();
                },
              ),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (value) {
              _filterNotes();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Just close
              },
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterNotes();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
  //search prob
  bool get _isSearching => _searchController.text.isNotEmpty;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickNotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearchDialog(context);
            },
          ),
          if (_isSearching)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _filterNotes();
                });
              },
              child: const Text(
                'Show All',
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: _filteredNotes.isEmpty
          ? const Center(
        child: Text(
          'No notes available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return GestureDetector(
            onTap: () => _showNoteDetailDialog(context, note),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.deepPurple, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditNoteDialog(note);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context, note);
                    } else if (value == 'share') {
                      _shareNote(note);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text("New Note"),
      ),
    );
  }
}
