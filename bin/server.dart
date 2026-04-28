import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../lib/shared.dart';

class ChatServer {
  final int port;
  final List<Socket> _clients = [];
  late ServerSocket _server;

  ChatServer({this.port = ChatConfig.defaultPort});

  Future<void> start() async {
    _server = await ServerSocket.bind(ChatConfig.defaultHost, port);
    print('CHAT SERVER: Listening on ${ChatConfig.defaultHost}:$port');

    _server.listen((Socket client) {
      _handleConnection(client);
    }, onError: (error) {
      print('SERVER ERROR: $error');
    });
  }

  void _handleConnection(Socket client) {
    print('CONNECTION: ${client.remoteAddress.address}:${client.remotePort} connected');
    _clients.add(client);

    client.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (String data) {
        try {
          final json = jsonDecode(data);
          final message = ChatMessage.fromJson(json);
          _processMessage(client, message);
        } catch (e) {
          print('PARSE ERROR from ${client.remoteAddress}: $e');
        }
      },
      onDone: () => _removeClient(client),
      onError: (e) => _removeClient(client),
    );
  }

  void _processMessage(Socket client, ChatMessage message) {
    // If it's a join message, we might want to store the username associated with the socket.
    // In this MVP, we just broadcast everything.
    broadcast(message);
  }

  void broadcast(ChatMessage message) {
    final encoded = jsonEncode(message.toJson()) + '\n';
    for (var client in _clients) {
      client.write(encoded);
    }
  }

  void _removeClient(Socket client) {
    print('DISCONNECTION: ${client.remoteAddress.address} disconnected');
    _clients.remove(client);
    client.close();
  }

  Future<void> stop() async {
    await _server.close();
    for (var client in _clients) {
      await client.close();
    }
    _clients.clear();
  }
}

void main(List<String> args) async {
  int port = ChatConfig.defaultPort;
  if (args.isNotEmpty) {
    port = int.tryParse(args[0]) ?? ChatConfig.defaultPort;
  }
  
  final server = ChatServer(port: port);
  await server.start();

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down server...');
    await server.stop();
    exit(0);
  });
}
