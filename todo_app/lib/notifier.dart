import 'package:flutter/widgets.dart';
import 'model.dart';

class TodoListNotifier with ChangeNotifier {
  final _todos = <Todo>[];

  int get length => _todos.length;

  Todo getTodo(int i) => _todos[i];

  void addTodo(String name) {
    if (name.trim().isEmpty) return;
    _todos.add(Todo(name: name, checked: false));
    notifyListeners();
  }

  void toggleTodo(Todo todo) {
    todo.checked = !todo.checked;
    notifyListeners();
  }

  void updateTodoText(Todo todo, String newText) {
    todo.name = newText;
    notifyListeners();
  }

  void deleteTodo(Todo todo) {
    _todos.remove(todo);
    notifyListeners();
  }
}
