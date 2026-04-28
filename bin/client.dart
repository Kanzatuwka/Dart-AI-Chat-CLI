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

      _socket.transform(utf8.decoder).transform(const LineSplitter()).listen(
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
      // Give some time for the message to be sent
      await Future.delayed(const Duration(milliseconds: 500));
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
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) async {
    if (line.trim().toLowerCase() == '/exit') {
      client.disconnect('Goodbye everyone!').then((_) => exit(0));
    } else if (line.trim().startsWith('/ai_join')) {
      final parts = line.split(' ');
      final id = parts.length > 1 ? parts[1] : 'critic';

      String argToPass = id;
      if (id == '?' && aiEngine != null) {
        stdout.write('\x1B[35mGenerating mystery guest...\x1B[0m\n');
        try {
          final randomP = await aiEngine.generateRandomPersonality();
          argToPass = jsonEncode({
            'id': randomP.id,
            'name': randomP.name,
            'backstory': randomP.backstory,
            'farewell': randomP.farewell,
          });
          print('\x1B[35m$id became ${randomP.name}!\x1B[0m');
        } catch (e) {
          print('\x1B[31mFailed to generate mystery guest: $e\x1B[0m');
          stdout.write('> ');
          return;
        }
      }

      print('\x1B[33mAttempting to spawn AI...\x1B[0m');
      Process.start('dart', ['bin/ai_participant.dart', argToPass]).then((Process process) {
        process.stdout.transform(utf8.decoder).listen((data) => print('AI_LOG: $data'));
        process.stderr.transform(utf8.decoder).listen((data) => print('AI_ERR: $data'));
      }).catchError((e) => print('Failed to start AI: $e'));
      stdout.write('> ');
    } else if (line.isNotEmpty) {
      client.sendMessage(line);
      stdout.write('> ');
    }
  });
}
