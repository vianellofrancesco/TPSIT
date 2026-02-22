import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'model.dart';

class DatabaseHelper {
  static Future<Database> init() async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        color INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER NOT NULL PRIMARY KEY,
        note_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        checked INTEGER NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes (id)
      );
    ''');
  }

  // --- Notes ---

  static Future<List<Note>> getNotes() async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    final List<Map<String, dynamic>> result = await db.query('notes');
    if (result.isEmpty) return [];
    return result.map((row) => Note.fromMap(row)).toList();
  }

  static Future<int> insertNote(Note note) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    return await db.insert('notes', note.toMap());
  }

  static Future<void> deleteNote(Note note) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    await db.delete('todos', where: 'note_id = ?', whereArgs: [note.id]);
    await db.delete('notes', where: 'id = ?', whereArgs: [note.id]);
  }

  // --- Todos ---

  static Future<List<Todo>> getTodosForNote(int noteId) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    final List<Map<String, dynamic>> result = await db.query(
      'todos',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    if (result.isEmpty) return [];
    return result.map((row) => Todo.fromMap(row)).toList();
  }

  static Future<int> insertTodo(Todo todo) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    return await db.insert('todos', todo.toMap());
  }

  static Future<void> updateTodo(Todo todo) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    db.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  static Future<void> deleteTodo(Todo todo) async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    Database db = await openDatabase(path, version: 1);
    db.delete('todos', where: 'id = ?', whereArgs: [todo.id]);
  }
}