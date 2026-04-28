# Architecture Sketch - Dart CLI Chat

## Overview
The system follows a classic **Client-Server** architecture over TCP/IP using the Dart `dart:io` library. It is designed to be environment-agnostic, supporting both cloud-managed and local AI backends.

## Components

### 1. Chat Server
- **Role**: Manages connections, broadcasts messages, and handles room state.
- **Implementation**: `ServerSocket` listening on a specific port (default 1234 or command-line arg).
- **State**: Maintains a list of active `Socket` connections.
- **Logging**: Detailed broadcasting logs for monitoring participant activity.

### 2. Chat Client (User)
- **Role**: Allows human users to interact with the chat.
- **Implementation**: `Socket` connection to the server.
- **Interface**: CLI with synchronized message display (clears stdin echo to avoid double-printing).
- **Styling**: Deterministic nickname coloring using ANSI codes based on sender hash.

### 3. AI Participant (Autonomous Client)
- **Role**: Simulates a personality in the chat.
- **Implementation**: Runs as a separate process to maintain true concurrency.
- **Universal Bridge**: Uses `AIEngine` which supports:
  - **Gemini API**: Default via `GEMINI_API_KEY`.
  - **OpenAI/LMStudio**: Via `AI_BASE_URL` (e.g., `http://localhost:1234/v1`).
- **Network Awareness**: Inherits `CHAT_PORT` from the parent client process.

## Network Protocol
- **Transport**: TCP.
- **Data Format**: UTF-8 encoded JSON strings delimited by newlines.
- **Message Types**:
  - `join`: Initial connection with identity info.
  - `message`: Public chat message.
  - `system`: Server announcements (joins, leaves).
  - `leave`: Graceful disconnection notification.

## Sequence Diagram (High-Level)
1. Server starts and listens on a designated port.
2. User Client connects and broadcasts a `join` event.
3. User triggers `/ai_join` -> Parent spawns a new `ai_participant.dart` process.
4. AI Client connects to server and broadcasts its entry.
5. AI Client monitors the stream, building a 20-message local context buffer.
6. AI Client executes its "Thinking Loop" (Stochastic Skip + Variable Delay).
7. AI Client requests response from the configured AI Engine (Universal Bridge).
8. AI Client broadcasts response or executes "Soft Shutdown" (Farewell + Leave) after 5 minutes.
