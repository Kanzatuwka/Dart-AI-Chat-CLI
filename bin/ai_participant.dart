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
    print('AI_DEBUG: Listener started for ${personality.name}');
    client.messages.listen((msg) {
      if (_isTerminating) return;
      
      // Don't respond to self
      if (msg.sender == personality.name) return;

      print('AI_DEBUG (${personality.name}): Received: ${msg.sender}: ${msg.content}');

      // Add to history
      _history.add("${msg.sender}: ${msg.content}");
      if (_history.length > 20) _history.removeAt(0);

      // Debounce reaction to mimic "reading/thinking" and avoid spamming
      _scheduleReaction();
    });
  }

  void _scheduleReaction() {
    _reactionTimer?.cancel();
    // Use a variable delay to feel more natural (3-8 seconds)
    final delay = 3 + (DateTime.now().millisecond % 5); 
    
    _reactionTimer = Timer(Duration(seconds: delay), () async {
      if (_isTerminating) return;
      
      // Stochastic behavior: maybe skip if it's too quiet or just random
      if (_history.isNotEmpty && DateTime.now().millisecond % 100 > 90) {
        print('AI_DEBUG (${personality.name}): Decided to stay quiet for this turn.');
        return;
      }
      
      print('AI_DEBUG (${personality.name}): Requesting AI response...');
      final response = await engine.generateResponse(personality, _history);
      
      if (!_isTerminating && response.isNotEmpty && response != "...") {
        print('AI_DEBUG (${personality.name}): Sending: $response');
        client.sendMessage(response);
      }
    });
  }

  Future<void> shutdown() async {
    if (_isTerminating) return;
    _isTerminating = true;
    _reactionTimer?.cancel();
    
    print('AI_LOG: Soft Shutdown - ${personality.name} is leaving.');
    
    try {
      // Send the farewell message before closing the socket
      await client.disconnect(personality.farewell);
      print('AI_LOG: Farewell sent successfully for ${personality.name}');
    } catch (e) {
      print('AI_LOG_ERROR: Failed to send farewell: $e');
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
  print('AI_DEBUG: Connecting ${personality.name} to port $port...');
  await client.connect(port: port);

  final ai = AIParticipant(personality, client, engine);
  ai.start();

  print('AI_LOG: Participant ${personality.name} joined the chat.');

  // Simulation limit to prevent token waste as requested
  Timer(const Duration(minutes: 5), () async {
    print('AI_LOG: 5-minute session limit reached for ${personality.name}.');
    await ai.shutdown();
    exit(0);
  });

  ProcessSignal.sigint.watch().listen((_) async {
    print('\nAI_LOG: External interrupt triggered shutdown for ${personality.name}.');
    await ai.shutdown();
    exit(0);
  });
}
