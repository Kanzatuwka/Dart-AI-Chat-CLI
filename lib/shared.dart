/// Shared constants and message structures for the Chat application.
class ChatConfig {
  static const int defaultPort = 8080;
  static const String defaultHost = '0.0.0.0';
}

/// Represents the type of message being sent.
enum MessageType { join, message, system, leave }

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

  static String _getColorForSender(String sender) {
    final colors = [
      '\x1B[31m', // Red
      '\x1B[32m', // Green
      '\x1B[33m', // Yellow
      '\x1B[34m', // Blue
      '\x1B[35m', // Magenta
      '\x1B[36m', // Cyan
      '\x1B[91m', // Light Red
      '\x1B[92m', // Light Green
      '\x1B[93m', // Light Yellow
      '\x1B[94m', // Light Blue
      '\x1B[95m', // Light Magenta
      '\x1B[96m', // Light Cyan
    ];
    final hash = sender
        .split('')
        .fold(0, (int prev, char) => prev + char.codeUnitAt(0));
    return colors[hash % colors.length];
  }

  @override
  String toString() {
    final timeStr =
        "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    final nameColor = _getColorForSender(sender);
    const reset = '\x1B[0m';

    switch (type) {
      case MessageType.system:
        return "$reset\x1B[33m[$timeStr] SYSTEM: $content$reset";
      case MessageType.message:
        return "$reset\x1B[90m[$timeStr]\x1B[0m $nameColor$sender:$reset $content";
      case MessageType.join:
        return "$reset\x1B[34m[$timeStr] >>> $sender has joined the chat$reset";
      case MessageType.leave:
        return "$reset\x1B[31m[$timeStr] <<< $sender has left the chat$reset";
    }
  }
}
