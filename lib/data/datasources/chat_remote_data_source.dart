import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/auth_service.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// Remote data source for chat messages using Cloud Firestore.
class ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _messagesRef(String roomId) {
    return _firestore.collection('rooms').doc(roomId).collection('messages');
  }

  /// Send a text message.
  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final uid = AuthService.currentUid;
    final name = AuthService.displayName;

    await _messagesRef(roomId).add(ChatMessageModel.toMap(
      ChatMessage(
        id: '', // Firestore will generate
        senderUid: uid,
        senderName: name,
        text: text,
        timestamp: DateTime.now(),
        type: MessageType.text,
      ),
    ));
  }

  /// Send a system message (e.g., "User joined", "Playback paused").
  Future<void> sendSystemMessage({
    required String roomId,
    required String text,
  }) async {
    await _messagesRef(roomId).add(ChatMessageModel.toMap(
      ChatMessage(
        id: '',
        senderUid: 'system',
        senderName: 'System',
        text: text,
        timestamp: DateTime.now(),
        type: MessageType.system,
      ),
    ));
  }

  /// Listen to chat messages in real-time (ordered by timestamp).
  Stream<List<ChatMessage>> listenToMessages(String roomId) {
    return _messagesRef(roomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Delete all messages in a room (cleanup).
  Future<void> deleteRoomMessages(String roomId) async {
    final batch = _firestore.batch();
    final snapshot = await _messagesRef(roomId).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
