import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

 
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _host = TextEditingController(text: 'localhost');
  final _port = TextEditingController(text: '8080');

  void _connect() async {
    if (_username.text.isEmpty) return;

    try {
      final socket = await Socket.connect(
        _host.text,
        int.parse(_port.text),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              socket: socket,
              username: _username.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _host,
              decoration: const InputDecoration(labelText: 'Host'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _port,
              decoration: const InputDecoration(labelText: 'Porta'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Connetti'),
            ),
          ],
        ),
      ),
    );
  }
}

 
class ChatScreen extends StatefulWidget {
  final Socket socket;
  final String username;

  const ChatScreen({
    Key? key,
    required this.socket,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> _messages = [];
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    
    widget.socket.write('${widget.username}\n');
    
    
    widget.socket.listen(
      (data) {
        setState(() {
          _messages.add(utf8.decode(data).trim());
        });
      },
      onDone: () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
    );
  }

  void _send() {
    if (_input.text.isEmpty) return;
    
    widget.socket.write('${_input.text}\n');
    setState(() {
      _messages.add('Tu: ${_input.text}');
    });
    _input.clear();
  } 
  
  
  @override
  void dispose() {
    _input.dispose();
    widget.socket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              widget.socket.close();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Nessun messaggio'))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(_messages[i]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      hintText: 'Messaggio...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}