import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/room_remote_data_source.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../core/utils/auth_service.dart';
import 'watch_room_state.dart';

/// Cubit managing Watch Together room state.
class WatchRoomCubit extends Cubit<WatchRoomState> {
  final RoomRemoteDataSource _roomDataSource;
  final ChatRemoteDataSource _chatDataSource;

  StreamSubscription? _roomSubscription;
  String? _currentRoomId;

  WatchRoomCubit({
    required RoomRemoteDataSource roomDataSource,
    required ChatRemoteDataSource chatDataSource,
  })  : _roomDataSource = roomDataSource,
        _chatDataSource = chatDataSource,
        super(WatchRoomInitial());

  String? get currentRoomId => _currentRoomId;

  /// Create a new watch room.
  Future<void> createRoom({
    required int contentId,
    required String contentType,
    int? season,
    int? episode,
    String? subOrDub,
  }) async {
    emit(const WatchRoomLoading(message: 'Creating room...'));

    try {
      final room = await _roomDataSource.createRoom(
        contentId: contentId,
        contentType: contentType,
        season: season,
        episode: episode,
        subOrDub: subOrDub,
      );

      _currentRoomId = room.roomId;
      emit(WatchRoomCreated(room));

      // Send system message
      await _chatDataSource.sendSystemMessage(
        roomId: room.roomId,
        text: '${AuthService.displayName} created the room',
      );

      // Start listening to room updates
      _listenToRoom(room.roomId);
    } catch (e) {
      emit(WatchRoomError(e.toString()));
    }
  }

  /// Join an existing room by code.
  Future<void> joinRoom(String roomCode) async {
    emit(const WatchRoomLoading(message: 'Joining room...'));

    try {
      final room = await _roomDataSource.joinRoom(roomCode);
      _currentRoomId = room.roomId;

      // Send system message
      await _chatDataSource.sendSystemMessage(
        roomId: room.roomId,
        text: '${AuthService.displayName} joined the room',
      );

      // Start listening
      _listenToRoom(room.roomId);
    } catch (e) {
      emit(WatchRoomError(e.toString()));
    }
  }

  /// Listen to room state changes.
  void _listenToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _roomDataSource.listenToRoom(roomId).listen(
      (room) {
        if (isClosed) return;
        final uid = AuthService.currentUid;

        // Check if any member is disconnected
        final disconnectedMembers = room.members.values
            .where((m) => !m.isOnline && m.uid != uid)
            .toList();

        final partnerDisconnected = disconnectedMembers.isNotEmpty;
        String? disconnectMsg;
        if (partnerDisconnected) {
          final names = disconnectedMembers.map((m) => m.displayName).join(', ');
          disconnectMsg = '$names lost connection...';
        }

        emit(WatchRoomActive(
          room: room,
          partnerDisconnected: partnerDisconnected,
          disconnectMessage: disconnectMsg,
        ));
      },
      onError: (error) {
        if (isClosed) return;
        if (error.toString().contains('deleted')) {
          emit(const WatchRoomClosed(reason: 'Room has been closed.'));
        } else {
          emit(WatchRoomError(error.toString()));
        }
      },
    );
  }

  /// Update playback state (play/pause/seek).
  Future<void> updatePlayback({
    required bool isPlaying,
    double? currentTime,
  }) async {
    if (_currentRoomId == null) return;

    try {
      await _roomDataSource.updatePlaybackState(
        roomId: _currentRoomId!,
        isPlaying: isPlaying,
        currentTime: currentTime,
        reason: 'user',
      );
    } catch (e) {
      // Silently handle - the room state will update via stream
    }
  }

  /// Listen to an existing room by its room ID (used when navigating to /room/:id).
  void listenToExistingRoom(String roomId) {
    _currentRoomId = roomId;
    emit(const WatchRoomLoading(message: 'Connecting to room...'));
    _roomDataSource.setMemberOnline(roomId);
    _listenToRoom(roomId);
  }

  /// Leave the current room.
  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;

    try {
      // Send system message before leaving
      await _chatDataSource.sendSystemMessage(
        roomId: _currentRoomId!,
        text: '${AuthService.displayName} left the room',
      );

      await _roomDataSource.leaveRoom(_currentRoomId!);
    } catch (_) {}

    _roomSubscription?.cancel();
    _currentRoomId = null;
    emit(const WatchRoomClosed(reason: 'You left the room.'));
  }

  /// Reconnect to the room (mark as online again).
  Future<void> reconnect() async {
    if (_currentRoomId == null) return;

    try {
      await _roomDataSource.setMemberOnline(_currentRoomId!);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _roomSubscription?.cancel();
    return super.close();
  }
}
