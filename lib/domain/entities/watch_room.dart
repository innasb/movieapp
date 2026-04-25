import 'package:equatable/equatable.dart';

/// Represents a Watch Together room.
class WatchRoom extends Equatable {
  final String roomId;
  final String roomCode;
  final String hostUid;
  final Map<String, RoomMember> members;
  final PlaybackState playbackState;
  final int contentId;
  final String contentType; // 'movie' | 'tv' | 'anime'
  final int? season;
  final int? episode;
  final String? subOrDub;
  final DateTime createdAt;

  const WatchRoom({
    required this.roomId,
    required this.roomCode,
    required this.hostUid,
    required this.members,
    required this.playbackState,
    required this.contentId,
    required this.contentType,
    this.season,
    this.episode,
    this.subOrDub,
    required this.createdAt,
  });

  /// Number of online members.
  int get onlineCount => members.values.where((m) => m.isOnline).length;

  /// Check if all members are online.
  bool get allMembersOnline => members.values.every((m) => m.isOnline);

  /// Check if at least one member is disconnected.
  bool get hasMemberDisconnected => members.values.any((m) => !m.isOnline);

  @override
  List<Object?> get props => [
        roomId, roomCode, hostUid, members, playbackState,
        contentId, contentType, season, episode, subOrDub, createdAt,
      ];
}

/// Represents a member in the watch room.
class RoomMember extends Equatable {
  final String uid;
  final String displayName;
  final bool isOnline;
  final DateTime joinedAt;
  final DateTime lastSeen;

  const RoomMember({
    required this.uid,
    required this.displayName,
    required this.isOnline,
    required this.joinedAt,
    required this.lastSeen,
  });

  @override
  List<Object?> get props => [uid, displayName, isOnline, joinedAt, lastSeen];
}

/// Represents the synchronized playback state for the room.
class PlaybackState extends Equatable {
  final bool isPlaying;
  final double currentTime; // seconds
  final DateTime updatedAt;
  final String updatedBy; // uid of who changed state
  final String reason; // 'user' | 'disconnect' | 'sync'

  const PlaybackState({
    required this.isPlaying,
    required this.currentTime,
    required this.updatedAt,
    required this.updatedBy,
    this.reason = 'user',
  });

  /// Default initial playback state.
  factory PlaybackState.initial(String uid) {
    return PlaybackState(
      isPlaying: false,
      currentTime: 0,
      updatedAt: DateTime.now(),
      updatedBy: uid,
      reason: 'user',
    );
  }

  @override
  List<Object?> get props => [isPlaying, currentTime, updatedAt, updatedBy, reason];
}
