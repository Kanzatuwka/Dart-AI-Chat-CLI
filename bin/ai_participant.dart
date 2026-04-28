import 'dart:async';
import 'dart:io';
import '../lib/shared.dart';
import '../lib/ai_engine.dart';
import 'client.dart';

class AIParticipant {
  final Personality personality;
  final ChatClient client;
  final AIEngine engine;
  final List<String> _history = [];
  Timer? _reactionTimer;
  bool _isTerminating = false;

  AIParticipant(this.personality, this.client, this.engine);

  void start() {
    client.messages.listen((msg) {
      if (_isTerminating) return;
      
      // Don't respond to self
      if (msg.sender == personality.name) return;

      // Add to history
      _history.add("${msg.sender}: ${msg.content}");
      if (_history.length > 20) _history.removeAt(0);

      // Debounce reaction to mimic "reading/thinking" and avoid spamming
      _scheduleReaction();
    });
  }

  void _scheduleReaction() {
    _reactionTimer?.cancel();
    // Increase delay to 5-15 seconds for less frequent chatter
    final delay = 5 + (DateTime.now().millisecond % 10); 
    
    _reactionTimer = Timer(Duration(seconds: delay), () async {
      if (_isTerminating) return;
      
      // Increase skip chance to 50% to prevent bots from dominating the chat
      if (_history.isNotEmpty && DateTime.now().millisecond % 100 > 50) {
        return;
      }
      
      final response = await engine.generateResponse(personality, _history);
      
      if (!_isTerminating && response.isNotEmpty && response != "...") {
        client.sendMessage(response);
      }
    });
  }

  Future<void> shutdown() async {
    if (_isTerminating) return;
    _isTerminating = true;
    _reactionTimer?.cancel();
    
    try {
      // Send the farewell message before closing the socket
      await client.disconnect(personality.farewell);
    } catch (_) {
      // Ignore errors during quiet shutdown
    }
  }
}

void main(List<String> args) async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  // engine handles empty key if LMStudio is used
  final engine = AIEngine(apiKey ?? '');
  
  Personality? personality;

  if (args.isNotEmpty) {
    try {
      // Check if argument is a JSON object (for dynamic "Mystery Guest")
      final data = jsonDecode(args[0]);
      if (data is Map<String, dynamic>) {
        personality = Personality(
          id: data['id'],
          name: data['name'],
          backstory: data['backstory'],
          farewell: data['farewell'],
        );
      }
    } catch (_) {
      // Not JSON, treat as ID
      personality = engine.personalities.firstWhere(
        (p) => p.id == args[0],
        orElse: () => engine.personalities.first,
      );
    }
  }

  personality ??= engine.personalities.first;

  // Find port from environment or default
  final portStr = Platform.environment['CHAT_PORT'] ?? ChatConfig.defaultPort.toString();
  final port = int.tryParse(portStr) ?? ChatConfig.defaultPort;

  final client = ChatClient(personality.name);
  await client.connect(port: port);

  final ai = AIParticipant(personality, client, engine);
  ai.start();

  // Simulation limit to prevent token waste as requested
  Timer(const Duration(minutes: 5), () async {
    await ai.shutdown();
    exit(0);
  });

  ProcessSignal.sigint.watch().listen((_) async {
    await ai.shutdown();
    exit(0);
  });
}
