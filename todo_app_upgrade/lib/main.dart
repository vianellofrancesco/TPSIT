import 'package:flutter/material.dart';
import 'helper.dart';
import 'model.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zKeep',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'zKeep'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Note> _notes = <Note>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DatabaseHelper.init();
    _updateNotes();
  }

  void _updateNotes() {
    DatabaseHelper.getNotes().then((notes) async {
      for (Note note in notes) {
        List<Todo> todos = await DatabaseHelper.getTodosForNote(note.id!);
        note.todos.addAll(todos);
      }
      setState(() {
        _notes.clear();
        _notes.addAll(notes);
      });
    });
  }

  void _addNewNote() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuova Nota'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Titolo della nota',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Note note = Note(
                    title: titleController.text,
                    color: _getRandomColor(),
                  );
                  DatabaseHelper.insertNote(note).then((newId) {
                    setState(() {
                      _notes.add(Note(
                        id: newId,
                        title: note.title,
                        color: note.color,
                      ));
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.yellow.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
      Colors.pink.shade100,
      Colors.teal.shade100,
    ];
    return colors[_notes.length % colors.length];
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
    });
    DatabaseHelper.deleteNote(note);
  }

  void _addTodoToNote(Note note) {
    final TextEditingController todoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuovo Todo'),
          content: TextField(
            controller: todoController,
            decoration: const InputDecoration(
              hintText: 'Cosa devi fare?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (todoController.text.trim().isNotEmpty) {
                  Todo todo = Todo(
                    noteId: note.id!,
                    name: todoController.text,
                    checked: false,
                  );
                  DatabaseHelper.insertTodo(todo).then((newId) {
                    setState(() {
                      note.todos.add(Todo(
                        id: newId,
                        noteId: note.id!,
                        name: todo.name,
                        checked: false,
                      ));
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTodo(Note note, Todo todo) {
    setState(() {
      todo.checked = !todo.checked;
    });
    DatabaseHelper.updateTodo(todo);
  }

  void _deleteTodo(Note note, Todo todo) {
    setState(() {
      note.todos.remove(todo);
    });
    DatabaseHelper.deleteTodo(todo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text(
                'Nessuna nota.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  return NoteCard(
                    note: _notes[index],
                    onDelete: () => _deleteNote(_notes[index]),
                    onAddTodo: () => _addTodoToNote(_notes[index]),
                    onToggleTodo: (todo) => _toggleTodo(_notes[index], todo),
                    onDeleteTodo: (todo) => _deleteTodo(_notes[index], todo),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        tooltip: 'Aggiungi Nota',
        child: const Icon(Icons.add),
      ),
    );
  }
}