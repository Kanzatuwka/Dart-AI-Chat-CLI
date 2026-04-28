# Architecture Sketch - Dart CLI Chat

## Overview
The system follows a classic **Client-Server** architecture over TCP/IP using the Dart `dart:io` library.

## Components

### 1. Chat Server
- **Role**: Manages connections, broadcasts messages, and handles room state.
- **Implementation**: `ServerSocket` listening on a specific port.
- **State**: Maintains a list of active `Socket` connections and their associated metadata (username, type).

### 2. Chat Client (User)
- **Role**: Allows human users to interact with the chat.
- **Implementation**: `Socket` connection to the server.
- **Interface**: CLI with dual-stream handling (reading from `stdin` for input, writing to `stdout` for received messages).

### 3. AI Participant (Autonomous Client)
- **Role**: Simulates a personality in the chat.
- **Implementation**: Runs as a client process (or a thread/isolate within a client) that connects to the server.
- **AI Engine**: Connects to Gemini API via `HttpClient`.

## Network Protocol
- **Transport**: TCP.
- **Data Format**: UTF-8 encoded JSON strings delimited by newlines.
- **Message Types**:
  - `join`: Initial connection with identity info.
  - `message`: Public chat message.
  - `system`: Server announcements (joins, leaves).
  - `command`: Specific actions (e.g., `/exit`, `/ai_join`).

## Sequence Diagram (Implicit)
1. Server starts and listens.
2. User Client connects -> sends `join` payload.
3. Server acknowledges and broadcasts "User joined" (System message).
4. User sends `message` -> Server broadcasts to all.
5. AI Client joins (triggered by user or launch) -> sends `join` with AI metadata.
6. Server broadcasts "AI [Personality] joined".
7. AI Client listens to messages -> reacts based on personality prompt.
8. AI Client leaves (soft shutdown) -> sends farewell `message` -> closes connection.
