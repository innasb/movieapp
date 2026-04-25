import 'package:equatable/equatable.dart';
import '../../domain/entities/watch_room.dart';

abstract class WatchRoomState extends Equatable {
  const WatchRoomState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any room action.
class WatchRoomInitial extends WatchRoomState {}

/// Creating or joining a room.
class WatchRoomLoading extends WatchRoomState {
  final String message;
  const WatchRoomLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

/// Room created successfully, waiting for others to join.
class WatchRoomCreated extends WatchRoomState {
  final WatchRoom room;
  const WatchRoomCreated(this.room);

  @override
  List<Object?> get props => [room];
}

/// Actively in a room — the main "watching" state.
class WatchRoomActive extends WatchRoomState {
  final WatchRoom room;
  final bool partnerDisconnected;
  final String? disconnectMessage;

  const WatchRoomActive({
    required this.room,
    this.partnerDisconnected = false,
    this.disconnectMessage,
  });

  @override
  List<Object?> get props => [room, partnerDisconnected, disconnectMessage];

  WatchRoomActive copyWith({
    WatchRoom? room,
    bool? partnerDisconnected,
    String? disconnectMessage,
  }) {
    return WatchRoomActive(
      room: room ?? this.room,
      partnerDisconnected: partnerDisconnected ?? this.partnerDisconnected,
      disconnectMessage: disconnectMessage ?? this.disconnectMessage,
    );
  }
}

/// Room was closed (all members left or room deleted).
class WatchRoomClosed extends WatchRoomState {
  final String reason;
  const WatchRoomClosed({this.reason = 'Room has been closed.'});

  @override
  List<Object?> get props => [reason];
}

/// Error state.
class WatchRoomError extends WatchRoomState {
  final String message;
  const WatchRoomError(this.message);

  @override
  List<Object?> get props => [message];
}
