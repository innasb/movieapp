import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';

/// Firestore serialization model for ChatMessage.
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderUid,
    required super.senderName,
    required super.text,
    required super.timestamp,
    super.type,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? 'Watcher',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] == 'system' ? MessageType.system : MessageType.text,
    );
  }

  static Map<String, dynamic> toMap(ChatMessage message) {
    return {
      'senderUid': message.senderUid,
      'senderName': message.senderName,
      'text': message.text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': message.type == MessageType.system ? 'system' : 'text',
    };
  }
}
