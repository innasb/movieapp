import 'package:equatable/equatable.dart';

/// Type of chat message.
enum MessageType {
  text,    // Regular user message
  system,  // System notification (join, leave, pause, etc.)
}

/// Represents a chat message in a Watch Together room.
class ChatMessage extends Equatable {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
  });

  /// Whether this message is from the system.
  bool get isSystem => type == MessageType.system;

  @override
  List<Object?> get props => [id, senderUid, senderName, text, timestamp, type];
}
