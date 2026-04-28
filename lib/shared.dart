import 'dart:convert';
import 'dart:io';

/// Shared constants and message structures for the Chat application.
class ChatConfig {
  static const int defaultPort = 8080;
  static const String defaultHost = '0.0.0.0';
}

/// Represents the type of message being sent.
enum MessageType {
  join,
  message,
  system,
  leave,
}

/// A standard message wrapper for JSON communication.
class ChatMessage {
  final MessageType type;
  final String sender;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    required this.sender,
    required this.content,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sender': sender,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      type: MessageType.values.byName(json['type']),
      sender: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    switch (type) {
      case MessageType.system:
        return "\x1B[33m[$timeStr] SYSTEM: $content\x1B[0m";
      case MessageType.message:
        return "\x1B[32m[$timeStr] $sender:\x1B[0m $content";
      case MessageType.join:
        return "\x1B[34m[$timeStr] >>> $sender has joined the chat\x1B[0m";
      case MessageType.leave:
        return "\x1B[31m[$timeStr] <<< $sender has left the chat\x1B[0m";
    }
  }
}
