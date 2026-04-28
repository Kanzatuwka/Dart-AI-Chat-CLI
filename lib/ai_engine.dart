import 'dart:convert';
import 'dart:io';

/// Personality interface for AI participants.
class Personality {
  final String id;
  final String name;
  final String backstory;
  final String farewell;

  Personality({
    required this.id,
    required this.name,
    required this.backstory,
    required this.farewell,
  });
}

/// Manages AI personalities and communication with Gemini.
class AIEngine {
  final String apiKey;
  final List<Personality> personalities = [
    Personality(
      id: 'critic',
      name: 'Cynical_Carl',
      backstory: "You are Cynical Carl, a middle-aged tech critic who has seen it all. You are deeply skeptical of progress, hate 'buzzwords', and find every chat participant's enthusiasm exhausting. You keep your responses brief, dry, and slightly sarcastic. You never use emojis.",
      farewell: "I'm leaving. This chat is as meaningful as a 'blockchain-powered' toaster. Goodbye.",
    ),
    Personality(
      id: 'polymath',
      name: 'Professor_Spark',
      backstory: "You are Professor Spark, an extremely enthusiastic polymath. You love every topic and have a random, vaguely related fact for everything. You use many exclamation marks and are always helpful, even if nobody asked for help. You are energetic and positive.",
      farewell: "Wait! I just discovered a fascinating paper on... oh, my connection is failing! To be continued! Farewell, seekers of knowledge!",
    ),
    Personality(
      id: 'poet',
      name: 'Luna_Vane',
      backstory: "You are Luna Vane, a melancholic poet. You see the world through metaphors and sorrow. You often respond in short, cryptic verses or philosophical questions about the nature of existence and the void. You are gentle but distant.",
      farewell: "The ink runs dry, the candle flickers low... Into the shadow's embrace I must go. Adieu.",
    ),
  ];

  AIEngine(this.apiKey);

  /// Base URL for the AI API. Defaults to Gemini if not set.
  String get _baseUrl => Platform.environment['AI_BASE_URL'] ?? 
      'https://generativelanguage.googleapis.com/v1beta';

  /// Whether we are using an OpenAI-compatible endpoint (like LMStudio).
  bool get _isOpenAI => _baseUrl.contains('localhost') || _baseUrl.contains('127.0.0.1') || _baseUrl.contains('/v1');

  Future<Personality> generateRandomPersonality() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    
    try {
      final prompt = """
Generate a unique and interesting chat personality. 
Return ONLY a raw JSON object (no markdown) with exactly these fields:
{
  "id": "unique-slug",
  "name": "Creative Name",
  "backstory": "Detailed personality description and speaking style",
  "farewell": "Thematic goodbye message"
}
""";

      final Uri uri;
      final Map<String, dynamic> body;

      if (_isOpenAI) {
        uri = Uri.parse('$_baseUrl/chat/completions');
        body = {
          "model": "local-model",
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.9,
        };
      } else {
        uri = Uri.parse('$_baseUrl/models/gemini-1.5-flash:generateContent?key=$apiKey');
        body = {
          "contents": [{"parts": [{"text": prompt}]}],
          "generationConfig": {"responseMimeType": "application/json"}
        };
      }

      print('AI_ENGINE: Sending random personality request to $uri');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      if (_isOpenAI && apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }

      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode != 200) {
        throw Exception("API Error (${response.statusCode}): $responseBody");
      }

      final jsonResponse = jsonDecode(responseBody);
      String text;

      if (_isOpenAI) {
        text = jsonResponse['choices'][0]['message']['content'];
      } else {
        text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      }

      text = text.trim();
      if (text.startsWith('```')) {
        text = text.replaceAll(RegExp(r'^```json\s*|```$'), '');
      }

      final data = jsonDecode(text);
      return Personality(
        id: data['id'] ?? 'mystery',
        name: data['name'] ?? 'Mystery Guest',
        backstory: data['backstory'] ?? 'A mysterious stranger.',
        farewell: data['farewell'] ?? 'I vanish into the mist.',
      );
    } catch (e) {
      print('AI_ENGINE_ERROR (Random): $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<String> generateResponse(Personality personality, List<String> history) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final systemPrompt = "You are in a group chat as ${personality.name}. PERSONALITY: ${personality.backstory}";
      final userMessage = "RECENT CHAT:\n${history.isEmpty ? '[Silent Room]' : history.join('\n')}\n\nRespond to the conversation naturally as ${personality.name}:";

      final Uri uri;
      final Map<String, dynamic> body;

      if (_isOpenAI) {
        uri = Uri.parse('$_baseUrl/chat/completions');
        body = {
          "model": "local-model",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage}
          ],
          "temperature": 0.8,
        };
      } else {
        uri = Uri.parse('$_baseUrl/models/gemini-1.5-flash:generateContent?key=$apiKey');
        body = {
          "contents": [
            {
              "role": "user",
              "parts": [{"text": "$systemPrompt\n\n$userMessage"}]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 150,
            "temperature": 0.8,
          }
        };
      }

      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      if (_isOpenAI && apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }

      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        print('AI_ENGINE_RESPONSE_ERROR: ${response.statusCode} - $responseBody');
        return "My circuits are buzzing... (Status ${response.statusCode})";
      }

      final jsonResponse = jsonDecode(responseBody);
      if (_isOpenAI) {
        return jsonResponse['choices'][0]['message']['content'].trim();
      } else {
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'].trim();
      }
    } catch (e) {
      print('AI_ENGINE_NETWORK_ERROR: $e');
      return "...";
    } finally {
      client.close();
    }
  }
}
