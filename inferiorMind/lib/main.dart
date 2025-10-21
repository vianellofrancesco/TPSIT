import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const List<Color> availableColors = [
    Colors.grey,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];
  List<int> buttonsColors = [0, 0, 0, 0];
  late List<Color> colorSetToGuess;
  int count = 0;

  void generateColorSetToGuess() {
    final random = Random();
    colorSetToGuess = List.generate(4, (index) {
      return availableColors[random.nextInt(availableColors.length)];
    });
  }

  @override
  void initState() {
    super.initState();
    generateColorSetToGuess();
  }

  void changeColor(int index) {
    setState(() {
      buttonsColors[index] =
          (buttonsColors[index] + 1) % availableColors.length;
    });
  }

  void checkVictory() {
    count++;
    for (int i = 0; i < buttonsColors.length; i++) {
      if (availableColors[buttonsColors[i]] != colorSetToGuess[i]) {
        setState(() {
          buttonsColors = [0, 0, 0, 0];
        });
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("HAI VINTO!!!"),
        content: Text("Hai indovinato i colori in $count tentativi."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                buttonsColors = [0, 0, 0, 0];
                count = 0;
                generateColorSetToGuess();
              });
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inferior Mind')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => changeColor(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: availableColors[buttonsColors[0]],
              ),
              child: const SizedBox(width: 50, height: 50),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => changeColor(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: availableColors[buttonsColors[1]],
              ),
              child: SizedBox(width: 50, height: 50),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => changeColor(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: availableColors[buttonsColors[2]],
              ),
              child: SizedBox(width: 50, height: 50),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => changeColor(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: availableColors[buttonsColors[3]],
              ),
              child: SizedBox(width: 50, height: 50),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: checkVictory,
        child: const Text("INVIO"),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
