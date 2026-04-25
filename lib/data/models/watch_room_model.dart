import '../../domain/entities/watch_room.dart';

/// Firebase serialization model for WatchRoom.
class WatchRoomModel extends WatchRoom {
  const WatchRoomModel({
    required super.roomId,
    required super.roomCode,
    required super.hostUid,
    required super.members,
    required super.playbackState,
    required super.contentId,
    required super.contentType,
    super.season,
    super.episode,
    super.subOrDub,
    required super.createdAt,
  });

  factory WatchRoomModel.fromMap(String roomId, Map<dynamic, dynamic> map) {
    // Parse members
    final membersMap = <String, RoomMember>{};
    if (map['members'] != null) {
      (map['members'] as Map<dynamic, dynamic>).forEach((uid, data) {
        membersMap[uid.toString()] = RoomMemberModel.fromMap(
          uid.toString(),
          Map<dynamic, dynamic>.from(data as Map),
        );
      });
    }

    // Parse playback state
    final playbackData = map['playbackState'] as Map<dynamic, dynamic>?;
    final playback = playbackData != null
        ? PlaybackStateModel.fromMap(playbackData)
        : PlaybackState.initial('');

    return WatchRoomModel(
      roomId: roomId,
      roomCode: map['roomCode']?.toString() ?? '',
      hostUid: map['hostUid']?.toString() ?? '',
      members: membersMap,
      playbackState: playback,
      contentId: (map['contentId'] as num?)?.toInt() ?? 0,
      contentType: map['contentType']?.toString() ?? 'movie',
      season: (map['season'] as num?)?.toInt(),
      episode: (map['episode'] as num?)?.toInt(),
      subOrDub: map['subOrDub']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostUid': hostUid,
      'contentId': contentId,
      'contentType': contentType,
      if (season != null) 'season': season,
      if (episode != null) 'episode': episode,
      if (subOrDub != null) 'subOrDub': subOrDub,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'playbackState': PlaybackStateModel.toMapStatic(playbackState),
    };
  }
}

/// Firebase serialization for RoomMember.
class RoomMemberModel extends RoomMember {
  const RoomMemberModel({
    required super.uid,
    required super.displayName,
    required super.isOnline,
    required super.joinedAt,
    required super.lastSeen,
  });

  factory RoomMemberModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return RoomMemberModel(
      uid: uid,
      displayName: map['displayName']?.toString() ?? 'Watcher',
      isOnline: map['isOnline'] as bool? ?? false,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['joinedAt'] as num?)?.toInt() ?? 0,
      ),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        (map['lastSeen'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  static Map<String, dynamic> toMap(RoomMember member) {
    return {
      'displayName': member.displayName,
      'isOnline': member.isOnline,
      'joinedAt': member.joinedAt.millisecondsSinceEpoch,
      'lastSeen': member.lastSeen.millisecondsSinceEpoch,
    };
  }
}

/// Firebase serialization for PlaybackState.
class PlaybackStateModel extends PlaybackState {
  const PlaybackStateModel({
    required super.isPlaying,
    required super.currentTime,
    required super.updatedAt,
    required super.updatedBy,
    super.reason,
  });

  factory PlaybackStateModel.fromMap(Map<dynamic, dynamic> map) {
    return PlaybackStateModel(
      isPlaying: map['isPlaying'] as bool? ?? false,
      currentTime: (map['currentTime'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num?)?.toInt() ?? 0,
      ),
      updatedBy: map['updatedBy']?.toString() ?? '',
      reason: map['reason']?.toString() ?? 'user',
    );
  }

  static Map<String, dynamic> toMapStatic(PlaybackState state) {
    return {
      'isPlaying': state.isPlaying,
      'currentTime': state.currentTime,
      'updatedAt': state.updatedAt.millisecondsSinceEpoch,
      'updatedBy': state.updatedBy,
      'reason': state.reason,
    };
  }
}
