import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../lib/shared.dart';
import '../lib/ai_engine.dart';

class ChatClient {
  final String username;
  late Socket _socket;
  final StreamController<ChatMessage> _messageStream = StreamController.broadcast();

  ChatClient(this.username);

  Stream<ChatMessage> get messages => _messageStream.stream;

  Future<void> connect({String host = 'localhost', int port = ChatConfig.defaultPort}) async {
    try {
      _socket = await Socket.connect(host, port);
      
      // Send join message
      _send(ChatMessage(
        type: MessageType.join,
        sender: username,
        content: '',
      ));

      _socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (String data) {
          try {
            final json = jsonDecode(data);
            final message = ChatMessage.fromJson(json);
            _messageStream.add(message);
          } catch (e) {
            // Ignore malformed messages
          }
        },
        onDone: () {
          print('\x1B[31mDisconnected from server.\x1B[0m');
          exit(0);
        },
      );
    } catch (e) {
      print('Connection failed: $e');
      rethrow;
    }
  }

  void sendMessage(String content) {
    _send(ChatMessage(
      type: MessageType.message,
      sender: username,
      content: content,
    ));
  }

  void _send(ChatMessage message) {
    _socket.write(jsonEncode(message.toJson()) + '\n');
  }

  Future<void> disconnect([String? farewell]) async {
    if (farewell != null) {
      sendMessage(farewell);
      // Give more time for the message to be propagated and broadcasted
      await Future.delayed(const Duration(seconds: 1));
    }
    _send(ChatMessage(
      type: MessageType.leave,
      sender: username,
      content: '',
    ));
    await _socket.flush();
    await _socket.close();
  }
}

void main(List<String> args) async {
  String? username;
  int port = ChatConfig.defaultPort;

  if (args.isNotEmpty) {
    username = args[0];
    if (args.length > 1) {
      port = int.tryParse(args[1]) ?? ChatConfig.defaultPort;
    }
  }

  if (username == null) {
    stdout.write('Enter your username: ');
    username = stdin.readLineSync();
    if (username == null || username.isEmpty) return;
  }

  final client = ChatClient(username);
  await client.connect(port: port);

  final apiKey = Platform.environment['GEMINI_API_KEY'];
  final aiEngine = apiKey != null ? AIEngine(apiKey) : null;

  client.messages.listen((msg) {
    // Clear current line before printing received message
    stdout.write('\r'); 
    print(msg);
    stdout.write('> '); 
  });

  stdout.write('> ');
  stdin.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen((String line) async {
    if (line.trim().toLowerCase() == '/exit') {
      client.disconnect('Goodbye everyone!').then((_) => exit(0));
    } else if (line.trim().startsWith('/ai_join')) {
      final parts = line.split(' ');
      final id = parts.length > 1 ? parts[1] : 'critic';

      String argToPass = id;
      if (id == '?' && aiEngine != null) {
        try {
          final randomP = await aiEngine.generateRandomPersonality();
          argToPass = jsonEncode({
            'id': randomP.id,
            'name': randomP.name,
            'backstory': randomP.backstory,
            'farewell': randomP.farewell,
          });
        } catch (e) {
          stdout.write('> ');
          return;
        }
      }

      // Inherit and extend environment
      final env = Map<String, String>.from(Platform.environment);
      env['CHAT_PORT'] = client._socket.remotePort.toString();
      
      Process.start('dart', ['bin/ai_participant.dart', argToPass], environment: env).then((Process process) {
        // Quietly listen without printing logs to local UI
        process.stdout.listen((_) {});
        process.stderr.listen((_) {});
      }).catchError((_) {});
      stdout.write('> ');
    } else if (line.isNotEmpty) {
      client.sendMessage(line);
      stdout.write('> ');
    }
  });
}
