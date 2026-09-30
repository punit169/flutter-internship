import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/note.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const QuickNotesApp());

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSpace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
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
  // Navigation tab index: 0 = Notes, 1 = To-Do Tasks
  int _selectedTabIndex = 0;

  // Inline search state
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  // Notes state
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  // To-Do Tasks state
  List<TodoTask> _todos = [];
  List<TodoTask> _filteredTodos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final notesData = prefs.getStringList('notes') ?? [];
    final loadedNotes =
        notesData.map((e) => Note.fromJson(json.decode(e))).toList();

    final todosData = prefs.getStringList('todos') ?? [];
    final loadedTodos =
        todosData.map((e) => TodoTask.fromJson(json.decode(e))).toList();

    setState(() {
      _notes = loadedNotes;
      _filteredNotes = List.from(loadedNotes);
      _todos = loadedTodos;
      _filteredTodos = List.from(loadedTodos);
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notes.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList('notes', data);
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _todos.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList('todos', data);
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = List.from(_notes);
        _filteredTodos = List.from(_todos);
      } else {
        _filteredNotes = _notes
            .where((note) =>
                note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query))
            .toList();
        _filteredTodos = _todos
            .where((todo) => todo.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // -------------------- FORMAT & CLIPBOARD HELPERS --------------------

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = targetDay.difference(today).inDays;

    String dayPart;
    if (diffDays == 0) {
      dayPart = 'Today';
    } else if (diffDays == 1) {
      dayPart = 'Tomorrow';
    } else if (diffDays == -1) {
      dayPart = 'Yesterday';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      dayPart = '$d/$m/${dt.year}';
    }

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dayPart, $hour12:$minute $period';
  }

  Future<DateTime?> _pickReminderDateTime(
    BuildContext context,
    DateTime? initial,
  ) async {
    final now = DateTime.now();
    final initialDate = (initial != null && initial.isAfter(now))
        ? initial
        : now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !context.mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _copyToClipboard(String text, {String label = 'Note'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyNote(Note note) {
    final textToCopy = note.title.trim().isEmpty
        ? note.content
        : (note.content.trim().isEmpty
            ? note.title
            : '${note.title}\n\n${note.content}');
    _copyToClipboard(textToCopy, label: 'Note');
  }

  void _shareNote(Note note) {
    final String textToShare = '${note.title}\n\n${note.content}'.trim();
    Share.share(
      textToShare.isEmpty ? '(Empty Note)' : textToShare,
      subject: 'Note: ${note.title}',
    );
  }

  // -------------------- NOTES CRUD --------------------

  void _addNote(String title, String content, DateTime? reminderDate) {
    if (title.trim().isEmpty && content.trim().isEmpty) return;
    final newNote = Note(
      title: title.trim(),
      content: content.trim(),
      date: DateTime.now(),
      reminderDate: reminderDate,
    );
    setState(() {
      _notes.add(newNote);
    });
    _applyFilter();
    _saveNotes();
  }

  void _deleteNote(Note note) {
    final deletedIndex = _notes.indexOf(note);
    if (deletedIndex == -1) return;

    setState(() {
      _notes.removeAt(deletedIndex);
    });
    _applyFilter();
    _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final insertIdx = deletedIndex.clamp(0, _notes.length);
              _notes.insert(insertIdx, note);
            });
            _applyFilter();
            _saveNotes();
          },
        ),
      ),
    );
  }

  // -------------------- TO-DO TASKS CRUD --------------------

  void _addTodo(String title, DateTime? reminderDate) {
    if (title.trim().isEmpty) return;
    final newTask = TodoTask(
      title: title.trim(),
      reminderDate: reminderDate,
    );
    setState(() {
      _todos.add(newTask);
    });
    _applyFilter();
    _saveTodos();
  }

  void _toggleTodo(TodoTask task) {
    setState(() {
      task.isDone = !task.isDone;
    });
    _saveTodos();
  }

  void _deleteTodo(TodoTask task) {
    final deletedIndex = _todos.indexOf(task);
    if (deletedIndex == -1) return;

    setState(() {
      _todos.removeAt(deletedIndex);
    });
    _applyFilter();
    _saveTodos();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final insertIdx = deletedIndex.clamp(0, _todos.length);
              _todos.insert(insertIdx, task);
            });
            _applyFilter();
            _saveTodos();
          },
        ),
      ),
    );
  }

  // -------------------- OPTIONAL REMINDER PICKER WIDGET --------------------

  Widget _buildOptionalReminderSection({
    required BuildContext dialogContext,
    required DateTime? selectedReminder,
    required ValueChanged<DateTime?> onReminderChanged,
  }) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.notifications_none,
                size: 18, color: Colors.deepPurple),
            const SizedBox(width: 6),
            Text(
              'Reminder (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedReminder != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm_on,
                    size: 16, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatDateTime(selectedReminder),
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => onReminderChanged(null),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close,
                        size: 16, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: const Icon(Icons.schedule, size: 15),
                label: const Text('+1 Hour', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  onReminderChanged(now.add(const Duration(hours: 1)));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 15),
                label: const Text('Tomorrow 9 AM',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  final tomorrow = now.add(const Duration(days: 1));
                  onReminderChanged(
                    DateTime(
                        tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 15),
                label:
                    const Text('Pick Time', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final picked = await _pickReminderDateTime(
                    dialogContext,
                    selectedReminder,
                  );
                  if (picked != null) {
                    onReminderChanged(picked);
                  }
                },
              ),
            ],
          ),
      ],
    );
  }

  // -------------------- DIALOGS --------------------

  void _showNoteDetailDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? '(No Title)' : note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy Note',
                onPressed: () => _copyNote(note),
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                tooltip: 'Share Note',
                onPressed: () => _shareNote(note),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.reminderDate != null) ...[
                  _buildReminderBadge(note.reminderDate!),
                  const SizedBox(height: 12),
                ],
                SelectableText(
                  note.content.isEmpty ? '(No Content)' : note.content,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Created: ${_formatDateTime(note.date)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showEditNoteDialog(note);
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
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
    DateTime? selectedReminder;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Note'),
          content: SingleChildScrollView(
            child: Column(
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
                _buildOptionalReminderSection(
                  dialogContext: dialogContext,
                  selectedReminder: selectedReminder,
                  onReminderChanged: (newReminder) {
                    setDialogState(() {
                      selectedReminder = newReminder;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _addNote(titleCtrl.text, contentCtrl.text, selectedReminder);
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(Note note) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);
    DateTime? selectedReminder = note.reminderDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
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
                _buildOptionalReminderSection(
                  dialogContext: dialogContext,
                  selectedReminder: selectedReminder,
                  onReminderChanged: (newReminder) {
                    setDialogState(() {
                      selectedReminder = newReminder;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  note.title = titleCtrl.text.trim();
                  note.content = contentCtrl.text.trim();
                  note.reminderDate = selectedReminder;
                });
                _applyFilter();
                _saveNotes();
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Note note) {
    final displayTitle = note.title.isEmpty ? 'this note' : '"${note.title}"';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $displayTitle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(note);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditTodoDialog({TodoTask? existingTask}) {
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    DateTime? selectedReminder = existingTask?.reminderDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingTask == null ? 'New To-Do Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'What needs to be done?',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) return;
                    if (existingTask == null) {
                      _addTodo(value, selectedReminder);
                    } else {
                      setState(() {
                        existingTask.title = value.trim();
                        existingTask.reminderDate = selectedReminder;
                      });
                      _applyFilter();
                      _saveTodos();
                    }
                    Navigator.pop(dialogContext);
                  },
                ),
                _buildOptionalReminderSection(
                  dialogContext: dialogContext,
                  selectedReminder: selectedReminder,
                  onReminderChanged: (newReminder) {
                    setDialogState(() {
                      selectedReminder = newReminder;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (existingTask == null) {
                  _addTodo(titleCtrl.text, selectedReminder);
                } else {
                  setState(() {
                    existingTask.title = titleCtrl.text.trim();
                    existingTask.reminderDate = selectedReminder;
                  });
                  _applyFilter();
                  _saveTodos();
                }
                Navigator.pop(dialogContext);
              },
              child: Text(existingTask == null ? 'Add Task' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- UI WIDGET BUILDERS --------------------

  Widget _buildReminderBadge(DateTime reminderDate, {bool isDone = false}) {
    final isOverdue = !isDone && reminderDate.isBefore(DateTime.now());
    final color = isDone
        ? Colors.grey
        : (isOverdue ? Colors.red.shade700 : Colors.deepPurple);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.notification_important : Icons.alarm,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDateTime(reminderDate),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearchOpen) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearchOpen = false;
              _searchController.clear();
              _applyFilter();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _selectedTabIndex == 0
                ? 'Search notes...'
                : 'Search tasks...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                _applyFilter();
              },
            ),
        ],
      );
    }

    return AppBar(
      title: Text(
        _selectedTabIndex == 0 ? 'QuickSpace • Notes' : 'QuickSpace • To-Do',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            setState(() {
              _isSearchOpen = true;
            });
          },
        ),
        if (_selectedTabIndex == 1 && _todos.any((t) => t.isDone))
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear completed tasks',
            onPressed: () {
              setState(() {
                _todos.removeWhere((t) => t.isDone);
              });
              _applyFilter();
              _saveTodos();
            },
          ),
      ],
    );
  }

  Widget _buildNotesTab() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? 'No matching notes found.'
              : 'No notes available.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      // Extra bottom padding (96px) prevents the FloatingActionButton from
      // blocking the three-dot menu of the last note card!
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
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
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                note.title.isEmpty ? '(No Title)' : note.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: note.title.isEmpty
                      ? Colors.deepPurple.withValues(alpha: 0.5)
                      : Colors.deepPurple,
                  fontStyle:
                      note.title.isEmpty ? FontStyle.italic : FontStyle.normal,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.content.isNotEmpty)
                    Text(
                      note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (note.reminderDate != null)
                    _buildReminderBadge(note.reminderDate!),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditNoteDialog(note);
                  } else if (value == 'copy') {
                    _copyNote(note);
                  } else if (value == 'share') {
                    _shareNote(note);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context, note);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'copy',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Copy'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodosTab() {
    if (_filteredTodos.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? 'No matching tasks found.'
              : 'No tasks yet! Tap "+ New Task" to add one.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      // Extra bottom padding (96px) prevents the FloatingActionButton from
      // covering the three-dot menu of the last task card!
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: _filteredTodos.length,
      itemBuilder: (context, index) {
        final task = _filteredTodos[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: task.isDone
                  ? Colors.grey.shade400
                  : Colors.deepPurple,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Checkbox(
              value: task.isDone,
              activeColor: Colors.deepPurple,
              onChanged: (_) => _toggleTodo(task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: task.isDone ? Colors.grey : Colors.black87,
                decoration:
                    task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: task.reminderDate != null
                ? _buildReminderBadge(task.reminderDate!, isDone: task.isDone)
                : null,
            onTap: () => _toggleTodo(task),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddOrEditTodoDialog(existingTask: task);
                } else if (value == 'copy') {
                  _copyToClipboard(task.title, label: 'Task');
                } else if (value == 'delete') {
                  _deleteTodo(task);
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'copy',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copy'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _selectedTabIndex == 0 ? _buildNotesTab() : _buildTodosTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedTabIndex == 0
            ? _showAddNoteDialog
            : () => _showAddOrEditTodoDialog(),
        icon: const Icon(Icons.add),
        label: Text(_selectedTabIndex == 0 ? 'New Note' : 'New Task'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'To-Do',
          ),
        ],
      ),
    );
  }
}

