# Technical Specification - Chat System

## Functional Requirements
1. **Universal AI Backend**: Support for Google Gemini and local OpenAI-compatible endpoints (LMStudio/LocalAI).
2. **Deterministic Coloring**: Each user and AI bot receives a consistent ANSI color for their nickname based on a string hash.
3. **Synchronous UI**: CLI client suppresses double-printing by clearing the input echo before displaying the broadcasted message.
4. **Autonomous AI Life-Cycle**: AI participants run in independent processes with a hard 5-minute session limit and thematic farewells.
5. **UTF-8 Robustness**: Explicit encoding/decoding guards across all streams (Socket, Stdin, HttpClient) to ensure emojis and special characters persist.

## Implementation Details

### Universal AI Bridge (`AIEngine`)
- Detects backend type via `AI_BASE_URL` environment variable.
- Handles both Gemini JSON Schema and OpenAI Chat Completion formats.
- Supports "Mystery Guest" generation via stochastic personality prompting.

### AI Participant Logic (`AIParticipant`)
- **Stochastic Timing**: Variable delay (5-15s) between message receipt and response.
- **Anti-Spam**: 50% chance to skip a response turn to ensure human participants have space to speak.
- **Context Buffer**: Maintains the last 20 messages to ensure conversational continuity without excessive token usage.

### CLI Client Interface
- **ANSI Engine**: Comprehensive support for 12+ vibrant terminal colors.
- **Interactive Feedback**: Uses `\x1B[1A\x1B[2K\r` to clear the terminal's input line when a user's own message is broadcasted back.

## API Specification (JSON Message)
```json
{
  "type": "join" | "leave" | "message" | "system",
  "sender": "string",
  "content": "string",
  "timestamp": "ISO8601"
}
```

## Security & Reliability
- **Environment Isolation**: API Keys and Base URLs managed purely through system variables.
- **Connection Guards**: Socket casts to `List<int>` before decoding to avoid pipeline errors in modern Dart runtimes.
- **Soft Shutdown**: `ProcessSignal.sigint` watching to ensure even interrupted bots say goodbye.
