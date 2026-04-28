# Technical Specification - Chat System

## Functional Requirements
1. **Single Global Room**: All connections share one chat stream.
2. **CLI Navigation**: Pure text-based interface.
3. **AI Personalities**: Multiple selectable "bots" with distinct backstories.
4. **Soft Shutdown**: Graceful exit for AI participants with a contextual goodbye.
5. **No External Pub Packages**: Strict adherence to `dart:core`, `dart:io`, `dart:convert`, and `dart:async`.

## Implementation Details

### Server Logic
- `ChatServer` class:
  - `bind(String host, int port)`
  - `_handleClient(Socket socket)`
  - `broadcast(Map<String, dynamic> data, [Socket? exclude])`

### AI Personality Engine
- Interface `Personality`:
  - `name`: string
  - `masterPrompt`: string
  - `generateResponse(String context)`: returns Future<String>
- Rate Limiting: Implementation of a token-conscious delay to avoid API spam and mimic natural typing speed.

### Communication Flow
- Every incoming packet is verified for JSON integrity.
- Server handles "Dead Client" detection via heartbeat or TCP socket errors.

## Security Considerations
- Simple username sanitization.
- No password authentication required for this phase (MVP).
- API Key handling: Read from environment variables securely.

## Personalities Defined
1. **The Cynical Critic**: Highly skeptical, uses dry humor.
2. **The Enthusiastic Polymath**: Overly excited about every topic, shares random facts.
3. **The Melancholic Poet**: Responds in verse or philosophical musings.
