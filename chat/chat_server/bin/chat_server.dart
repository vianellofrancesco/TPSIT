import 'dart:io';
import 'dart:convert';
import 'dart:async';

class ChatServer {
  static const int port = 8080;
  final Map<Socket, String> clients = {};
  ServerSocket? server;

  Future<void> start() async {
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print('Server avviato su ${server!.address.address}:${server!.port}');
      print('In attesa di connessioni\n');

      await for (Socket client in server!) {
        handleClient(client);
      }
    } catch (e) {
      print('Errore: $e');
    }
  }

  void handleClient(Socket client) {
    print('Nuova connessione: ${client.remoteAddress.address}:${client.remotePort}');
    
    String? username;
    
    client.listen(
      (data) {
        String message = utf8.decode(data).trim();
        
        if (username == null) {
          username = message;
          clients[client] = username!;
          print('registrato come: $username');
          broadcast('$username si è unito alla chat', exclude: client);
        } else {
          print('$username: $message');
          broadcast('$username: $message', exclude: client);
        }
      },
      onDone: () {
        if (username != null) {
          print('Ti sei disconesso');
          broadcast('$username ha abbandonato la chat');
          clients.remove(client);
        }
        client.close();
      },
      onError: (error) {
        print('Errore con client $username: $error');
        clients.remove(client);
        client.close();
      },
    );
  }

  void broadcast(String message, {Socket? exclude}) {
    String formattedMessage = '$message\n';
    for (var client in clients.keys) {
      if (client != exclude) {
        try {
          client.write(formattedMessage);
        } catch (e) {
          print('Errore nell\'invio a ${clients[client]}: $e');
        }
      }
    }
  }

  void stop() {
    server?.close();
    for (var client in clients.keys) {
      client.close();
    }
    clients.clear();
    print('Server fermato');
  }
}

void main() async {
  final chatServer = ChatServer();
  await chatServer.start();
}