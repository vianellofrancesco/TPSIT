import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'notifier.dart';

class TodoItem extends StatelessWidget {
  TodoItem({required this.todo}) : super(key: ObjectKey(todo));

  final Todo todo;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black45,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TodoListNotifier notifier = context.watch<TodoListNotifier>();

    return ListTile(
      onTap: () {
        notifier.changeTodo(todo);
      },
      onLongPress: (() {
        notifier.deleteTodo(todo);
      }),
      leading: CircleAvatar(child: Text(todo.name[0])),
      title: Text(todo.name, style: _getTextStyle(todo.checked)),
    );
  }
}
