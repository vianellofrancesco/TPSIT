import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const ChronoApp());
}

class ChronoApp extends StatelessWidget {
  const ChronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const ChronoHomePage(),
    );
  }
}

class ChronoHomePage extends StatefulWidget {
  const ChronoHomePage({super.key});

  @override
  State<ChronoHomePage> createState() => _ChronoHomePageState();
}

class _ChronoHomePageState extends State<ChronoHomePage> {
  
  int _seconds = 0;

  Stream<int>? _tickerStream;
  StreamSubscription<int>? _tickerSubscription;
  Stream<int>? _secondsStream;
  StreamSubscription<int>? _secondsSubscription;


  Stream<int> _createTickerStream() {
    return Stream.periodic(const Duration(milliseconds: 100), (count) => count);
  }

  Stream<int> _createSecondsStream(Stream<int> ticker) async* {
    int tuckCount = 0;
    await for (final _ in ticker) {
      tuckCount++;
      if (tuckCount >= 10) {
        tuckCount = 0;
        yield 1;
      }
    }
  }


    void _startStreams(){
    
      if(_tickerStream != null) return;
      _tickerStream = _createTickerStream();
      _secondsStream = _createSecondsStream(_tickerStream!);
      _tickerSubscription = _tickerStream!.listen((_) {});
      _secondsSubscription = _secondsStream!.listen((x) {
        setState(() {
          _seconds += x;
        });
      });
    }

    void _pauseStreams(){
      
      _tickerSubscription?.pause();
      _secondsSubscription?.pause();
    }

    void _resumeStreams(){
      
      _tickerSubscription?.resume();
      _secondsSubscription?.resume();
    }

    void _stopStreams(){
      
      _tickerSubscription?.cancel();
      _secondsSubscription?.cancel();
      _tickerSubscription = null;
      _secondsSubscription = null;

    }

    void _formatTime(int totalSeconds) {
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      
}
  //utilizzare streambuilder per aggiornare ui
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(s
        child: Text('Chrono'),

      ),
    );
  }
}
