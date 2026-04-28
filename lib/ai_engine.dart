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

  Future<Personality> generateRandomPersonality() async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    
    final prompt = """
Generate a unique and interesting chat personality. 
Return ONLY a JSON object with the following fields:
- "id": a unique slug (string)
- "name": a creative name (string)
- "backstory": a detailed biography and instructions on how they speak (string)
- "farewell": a thematic goodbye message (string)

Be creative. The character could be an 18th-century pirate, a sentient microwave, a hyper-focused gamer, or a zen monk.
""";

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      
      final body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
          "responseMimeType": "application/json",
        }
      };

      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final data = jsonDecode(text);
        return Personality(
          id: data['id'],
          name: data['name'],
          backstory: data['backstory'],
          farewell: data['farewell'],
        );
      }
      throw Exception("Failed to generate personality");
    } finally {
      client.close();
    }
  }

  Future<String> generateResponse(Personality personality, List<String> history) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    
    // Construct prompt
    String prompt = "You are participating in a group chat.\n";
    prompt += "YOUR PERSONALITY: ${personality.backstory}\n\n";
    prompt += "RELEVANT CHAT HISTORY:\n";
    for (var msg in history) {
      prompt += "$msg\n";
    }
    prompt += "\nRespond as ${personality.name} to the latest messages. Keep it natural for a chat. Do not repeat your name in the response prefix.";

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      
      final body = {
        "contents": [
          {
            "parts": [{"text": prompt}]
          }
        ],
        "generationConfig": {
          "maxOutputTokens": 150,
          "temperature": 0.9,
        }
      };

      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        return "ERROR: AI could not generate response.";
      }
    } catch (e) {
      return "ERROR: Connection to AI failed.";
    } finally {
      client.close();
    }
  }
}
