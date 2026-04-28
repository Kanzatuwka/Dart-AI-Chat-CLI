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
    print('AI Starting: ${personality.name}');
    client.messages.listen((msg) {
      if (_isTerminating) return;
      
      // Don't respond to self
      if (msg.sender == personality.name) return;

      // Add to history
      _history.add("${msg.sender}: ${msg.content}");
      if (_history.length > 10) _history.removeAt(0);

      // Debounce reaction to mimic "reading/thinking" and avoid spamming
      _scheduleReaction();
    });
  }

  void _scheduleReaction() {
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(seconds: 4), () async {
      if (_isTerminating) return;
      
      // 30% chance to not respond to keep it natural
      if (DateTime.now().millisecond % 10 > 7) return;

      final response = await engine.generateResponse(personality, _history);
      if (!_isTerminating) {
        client.sendMessage(response);
      }
    });
  }

  Future<void> shutdown() async {
    _isTerminating = true;
    _reactionTimer?.cancel();
    print('AI Shutting down: ${personality.name}');
    await client.disconnect(personality.farewell);
  }
}

void main(List<String> args) async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('FATAL: GEMINI_API_KEY not found in environment.');
    exit(1);
  }

  final engine = AIEngine(apiKey);
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

  final client = ChatClient(personality.name);
  await client.connect();

  final ai = AIParticipant(personality, client, engine);
  ai.start();

  print('AI Participant ${personality.name} joined the chat.');

  // Simulation limit to prevent token waste as requested
  Timer(const Duration(minutes: 5), () async {
    print('AI Session limit reached. Soft shutdown...');
    await ai.shutdown();
    exit(0);
  });

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nAI Soft shutdown triggered...');
    await ai.shutdown();
    exit(0);
  });
}
