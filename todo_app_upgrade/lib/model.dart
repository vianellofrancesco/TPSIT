import 'package:flutter/material.dart';

class Todo {
  Todo({required this.id, required this.name, this.checked = false});

  final int? id;
  final String name;
  bool checked;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'checked': checked ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      name: map['name'],
      checked: map['checked'] == 1,
    );
  }
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.color,
    required this.todos,
  });

  final int id;
  final String title;
  final Color color;
  final List<Todo> todos;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      color: Color(map['color']),
      todos: [],
    );
  }
}
