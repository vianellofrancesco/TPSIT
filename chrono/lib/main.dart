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

enum ChronoState { start, stop, reset }
enum PauseState { pause, resume }

class _ChronoHomePageState extends State<ChronoHomePage> {
  int _seconds = 0;

  ChronoState _chronoState = ChronoState.start;
  PauseState _pauseState = PauseState.pause;

  StreamSubscription<int>? _subscription;

  
  Stream<int> _tickerStream() async* {
    int tickCount = 0;
    while (true) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield tickCount++;
    }
  }

  
  Stream<int> _secondsStream(Stream<int> ticker) async* {
    int currentSecond = 0;

    await for (final tick in ticker) {
      final newSecond = tick ~/ 10;

      if (newSecond != currentSecond) {
        currentSecond = newSecond;
        yield newSecond;
      }
    }
  }

  
  void _startChrono() {
    if (_subscription != null) return;

    final ticker = _tickerStream();
    final seconds = _secondsStream(ticker);

    _subscription = seconds.listen((second) {
      setState(() {
        _seconds = second;
      });
    });

    setState(() {
      _chronoState = ChronoState.stop;
      _pauseState = PauseState.pause;
    });
  }

  void _stopChrono() {
    _subscription?.cancel();
    _subscription = null;

    setState(() {
      _chronoState = ChronoState.reset;
    });
  }


  void _resetChrono() {
    setState(() {
      _seconds = 0;
      _chronoState = ChronoState.start;
      _pauseState = PauseState.pause;
    });
  }

  void _pauseChrono() {
    _subscription?.pause();

    setState(() {
      _pauseState = PauseState.resume;
    });
  }

  void _resumeChrono() {
    _subscription?.resume();

    setState(() {
      _pauseState = PauseState.pause;
    });
  }

 
  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }


  void _handleChronoButton() {
    switch (_chronoState) {
      case ChronoState.start:
        _startChrono();
        break;
      case ChronoState.stop:
        _stopChrono();
        break;
      case ChronoState.reset:
        _resetChrono();
        break;
    }
  }

 
  void _handlePauseButton() {
    if (_chronoState != ChronoState.stop) return;

    switch (_pauseState) {
      case PauseState.pause:
        _pauseChrono();
        break;
      case PauseState.resume:
        _resumeChrono();
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color chronoColor;
    IconData chronoIcon;
    String chronoLabel;

    switch (_chronoState) {
      case ChronoState.start:
        chronoColor = Colors.green;
        chronoIcon = Icons.play_arrow;
        chronoLabel = 'START';
        break;
      case ChronoState.stop:
        chronoColor = Colors.red;
        chronoIcon = Icons.stop;
        chronoLabel = 'STOP';
        break;
      case ChronoState.reset:
        chronoColor = Colors.blue;
        chronoIcon = Icons.refresh;
        chronoLabel = 'RESET';
        break;
    }

    final isPauseEnabled = _chronoState == ChronoState.stop;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CHRONO',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Text(
            _formatTime(_seconds),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
              letterSpacing: 8,
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'chronoBtn',
                  onPressed: _handleChronoButton,
                  backgroundColor: chronoColor,
                  child: Icon(chronoIcon, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  chronoLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'pauseBtn',
                  onPressed: isPauseEnabled ? _handlePauseButton : null,
                  backgroundColor: isPauseEnabled
                      ? (_pauseState == PauseState.pause
                          ? Colors.orange
                          : Colors.lightBlue)
                      : Colors.grey,
                  child: Icon(
                    _pauseState == PauseState.pause
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _pauseState == PauseState.pause ? 'PAUSE' : 'RESUME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPauseEnabled ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}