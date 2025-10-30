import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => __MyHomePageState();
}

class __MyHomePageState extends State<MyHomePage> {

  int _seconds = 0;
  String _controlState = 'START'; 
  String _pauseState = 'PAUSE'; 
  bool _isRunning = false;
  int _tuckCount = 0;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<int>? _secondsSubscription;

  
  Stream<int> _createTickerStream() {
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (count) => count, 
    );
  }

  Stream<int> _createSecondsStream(Stream<int> tickerStream) {
    return tickerStream.transform(
      StreamTransformer<int, int>.fromHandlers(
        handleData: (tuck, sink) {
          _tuckCount++;
        
          if (mounted) {
            setState(() {});
          }

          if (_tuckCount >= 10) {
            _tuckCount = 0; 
            sink.add(1);
          }
        },
      ),
    );
  }

  void _startStreams() {
    final tickerStream = _createTickerStream();
    final secondsStream = _createSecondsStream(tickerStream);
    _tickerSubscription = tickerStream.listen((_) {});
    
    _secondsSubscription = secondsStream.listen((secondIncrement) {
      if (mounted) {
        setState(() {
          _seconds += secondIncrement;
        });
      }
    });
  }

  void _stopStreams() {
    _tickerSubscription?.cancel();
    _secondsSubscription?.cancel();
    _tickerSubscription = null;
    _secondsSubscription = null;
  }

  void _handleControl() {
    setState(() {
      if (_controlState == 'START') {
        _isRunning = true;
        _controlState = 'STOP';
        _pauseState = 'PAUSE';
        _startStreams();
      } else if (_controlState == 'STOP') {
        _isRunning = false;
        _controlState = 'RESET';
        _stopStreams();
      } else if (_controlState == 'RESET') {
        _isRunning = false;
        _seconds = 0;
        _tuckCount = 0;
        _controlState = 'START';
        _pauseState = 'PAUSE';
      }
    });
  }

  
  void _handlePause() {
    if (!_isRunning) return;

    setState(() {
      if (_pauseState == 'PAUSE') {
        _pauseState = 'RESUME';
        _stopStreams();
      } else {
        _pauseState = 'PAUSE';
        _startStreams();
      }
    });
  }

    String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

 
}