import 'dart:io';
import 'dart:convert';
import 'dart:async';

class ChatClient {
  Socket? socket;
  String? username;

  Future<void> connect(String host, int port, String user) async {
    try {
      username = user;
      socket = await Socket.connect(host, port);
      print('Connesso al server $host:$port');
      
      socket!.write('$username\n');
      
      socket!.listen(
        (data) {
          String message = utf8.decode(data).trim();
          print(message);
        },
        onDone: () {
          print('\nDisconnesso dal server');
          exit(0);
        },
        onError: (error) {
          print('Errore: $error');
          exit(1);
        },
      );
      
    
      stdin.transform(utf8.decoder).listen((input) {
        String message = input.trim();
        if (message.isNotEmpty) {
          if (message.toLowerCase() == '/quit') {
            disconnect();
          } else {
            socket!.write('$message\n');
          }
        }
      });
      
    } catch (e) {
      print('Errore nella connessione: $e');
      exit(1);
    }
  }

  void disconnect() {
    socket?.close();
    print('Disconnessione in corso');
    exit(0);
  }
}

void main(List<String> args) async {
  print(' Client Chatroom \n');
  
  stdout.write('Inserisci il tuo username: ');
  String? username = stdin.readLineSync();
  
  if (username == null || username.trim().isEmpty) {
    print('non valido');
    exit(1);
  }
  
  String host = args.isNotEmpty ? args[0] : 'localhost';
  int port = args.length > 1 ? int.parse(args[1]) : 8080;
  
  print('\nConnessione a server come: $username');
  print('(Scrivi /quit per disconnetterti)\n');
  
  final client = ChatClient();
  await client.connect(host, port, username.trim());
}