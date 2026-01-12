import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'am043 todo list',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      home: ChangeNotifierProvider<TodoListNotifier>(
        create: (notifier) => TodoListNotifier(),
        child: const MyHomePage(title: 'am043 todo list'),
      ),
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
  final TextEditingController _textFieldController = TextEditingController();

  Future<void> _displayDialog(TodoListNotifier notifier) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('add todo item'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'type here ...'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
                notifier.addTodo(_textFieldController.text);
                _textFieldController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TodoListNotifier notifier = context.watch<TodoListNotifier>();

    return Scaffold(
      appBar: AppBar(
        shadowColor: Theme.of(context).shadowColor,
        elevation: 4,
        title: Text(widget.title),
      ),
      body: Center(
  
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: notifier.length,
          itemBuilder: (context, index) {
          Todo todo = notifier.getTodo(index);
        return Card(
          color: const Color.fromRGBO(255, 247, 138, 1), // Giallo sticky note
          elevation: 4,
          shadowColor: const Color.fromRGBO(0, 0, 0, 1),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Spazio tra le card
          child: TodoItem(todo: todo), // Il tuo widget va dentro la Card
        );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(notifier),
        tooltip: 'add todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
