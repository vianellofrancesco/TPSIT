import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoItem extends StatefulWidget {
  const TodoItem({required this.todo, super.key});

  final Todo todo;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo.name);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TodoListNotifier>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Checkbox(
            value: widget.todo.checked,
            onChanged: (_) => notifier.toggleTodo(widget.todo),
          ),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      notifier.updateTodoText(widget.todo, value);
                      setState(() => _editing = false);
                    },
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    onLongPress: () => notifier.deleteTodo(widget.todo),
                    child: Text(
                      widget.todo.name,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.todo.checked
                            ? Colors.black45
                            : Colors.black,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
