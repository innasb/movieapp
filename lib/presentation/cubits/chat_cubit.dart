import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import 'chat_state.dart';

/// Cubit managing real-time chat in a Watch Together room.
class ChatCubit extends Cubit<ChatState> {
  final ChatRemoteDataSource _chatDataSource;
  StreamSubscription? _chatSubscription;
  String? _roomId;

  ChatCubit({required ChatRemoteDataSource chatDataSource})
      : _chatDataSource = chatDataSource,
        super(ChatInitial());

  /// Start listening to chat messages for a room.
  void listenToChat(String roomId) {
    _roomId = roomId;
    emit(ChatLoading());

    _chatSubscription?.cancel();
    _chatSubscription = _chatDataSource.listenToMessages(roomId).listen(
      (messages) {
        emit(ChatLoaded(messages));
      },
      onError: (error) {
        emit(ChatError(error.toString()));
      },
    );
  }

  /// Send a text message.
  Future<void> sendMessage(String text) async {
    if (_roomId == null || text.trim().isEmpty) return;

    try {
      await _chatDataSource.sendMessage(
        roomId: _roomId!,
        text: text.trim(),
      );
    } catch (e) {
      // Message sending failed silently - the UI will show via stream
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
