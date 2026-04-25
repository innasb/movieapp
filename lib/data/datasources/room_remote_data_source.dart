import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../../core/utils/auth_service.dart';
import '../../domain/entities/watch_room.dart';
import '../models/watch_room_model.dart';

/// Remote data source for Watch Together rooms using Firebase Realtime Database.
class RoomRemoteDataSource {
  final FirebaseDatabase _database;

  RoomRemoteDataSource({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference get _roomsRef => _database.ref('rooms');
  DatabaseReference get _codesRef => _database.ref('roomCodes');

  /// Generate a 6-character room code that is easy to read and share.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new watch room.
  Future<WatchRoom> createRoom({
    required int contentId,
    required String contentType,
    int? season,
    int? episode,
    String? subOrDub,
  }) async {
    final user = await AuthService.ensureAuthenticated();
    final uid = user.uid;
    final displayName = AuthService.displayName;

    // Generate unique room code
    String roomCode;
    bool codeExists = true;
    do {
      roomCode = _generateRoomCode();
      final snapshot = await _codesRef.child(roomCode).get();
      codeExists = snapshot.exists;
    } while (codeExists);

    // Create room
    final roomRef = _roomsRef.push();
    final roomId = roomRef.key!;
    final now = DateTime.now();

    final roomData = WatchRoomModel(
      roomId: roomId,
      roomCode: roomCode,
      hostUid: uid,
      members: {
        uid: RoomMember(
          uid: uid,
          displayName: displayName,
          isOnline: true,
          joinedAt: now,
          lastSeen: now,
        ),
      },
      playbackState: PlaybackState.initial(uid),
      contentId: contentId,
      contentType: contentType,
      season: season,
      episode: episode,
      subOrDub: subOrDub,
      createdAt: now,
    );

    // Write room data
    await roomRef.set(roomData.toMap());

    // Write member data
    await roomRef.child('members/$uid').set({
      'displayName': displayName,
      'isOnline': true,
      'joinedAt': now.millisecondsSinceEpoch,
      'lastSeen': now.millisecondsSinceEpoch,
    });

    // Map room code to room ID for quick lookup
    await _codesRef.child(roomCode).set(roomId);

    // Set up disconnect hooks
    await _setupDisconnectHooks(roomId, uid);

    return roomData;
  }

  /// Join a room by its 6-character code.
  Future<WatchRoom> joinRoom(String roomCode) async {
    final user = await AuthService.ensureAuthenticated();
    final uid = user.uid;
    final displayName = AuthService.displayName;

    // Look up room ID from code
    final codeSnapshot = await _codesRef.child(roomCode.toUpperCase()).get();
    if (!codeSnapshot.exists) {
      throw Exception('Room not found. Check the code and try again.');
    }

    final roomId = codeSnapshot.value as String;

    // Check if room exists
    final roomSnapshot = await _roomsRef.child(roomId).get();
    if (!roomSnapshot.exists) {
      // Clean up stale code
      await _codesRef.child(roomCode.toUpperCase()).remove();
      throw Exception('This room no longer exists.');
    }

    final now = DateTime.now();

    // Add member to room
    await _roomsRef.child('$roomId/members/$uid').set({
      'displayName': displayName,
      'isOnline': true,
      'joinedAt': now.millisecondsSinceEpoch,
      'lastSeen': now.millisecondsSinceEpoch,
    });

    // Set up disconnect hooks
    await _setupDisconnectHooks(roomId, uid);

    // Fetch and return updated room
    final updatedSnapshot = await _roomsRef.child(roomId).get();
    return WatchRoomModel.fromMap(
      roomId,
      Map<dynamic, dynamic>.from(updatedSnapshot.value as Map),
    );
  }

  /// Leave a room. Cleans up if last member.
  Future<void> leaveRoom(String roomId) async {
    final uid = AuthService.currentUid;
    if (uid.isEmpty) return;

    // Remove member
    await _roomsRef.child('$roomId/members/$uid').remove();

    // Check if room is now empty
    final membersSnapshot = await _roomsRef.child('$roomId/members').get();
    if (!membersSnapshot.exists ||
        (membersSnapshot.value as Map?)?.isEmpty == true) {
      // Get room code before deleting
      final roomSnapshot = await _roomsRef.child(roomId).get();
      if (roomSnapshot.exists) {
        final roomData = Map<dynamic, dynamic>.from(roomSnapshot.value as Map);
        final roomCode = roomData['roomCode']?.toString();
        if (roomCode != null) {
          await _codesRef.child(roomCode).remove();
        }
      }
      // Delete the room
      await _roomsRef.child(roomId).remove();
    } else {
      // Pause playback when someone leaves
      await updatePlaybackState(
        roomId: roomId,
        isPlaying: false,
        currentTime: null,
        reason: 'user_left',
      );
    }
  }

  /// Listen to room state changes in real-time.
  Stream<WatchRoom> listenToRoom(String roomId) {
    return _roomsRef.child(roomId).onValue.map((event) {
      if (event.snapshot.value == null) {
        throw Exception('Room has been deleted.');
      }
      return WatchRoomModel.fromMap(
        roomId,
        Map<dynamic, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Update the playback state (play/pause/seek).
  Future<void> updatePlaybackState({
    required String roomId,
    required bool isPlaying,
    double? currentTime,
    String reason = 'user',
  }) async {
    final uid = AuthService.currentUid;
    final updates = <String, dynamic>{
      'isPlaying': isPlaying,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'updatedBy': uid,
      'reason': reason,
    };
    if (currentTime != null) {
      updates['currentTime'] = currentTime;
    }

    await _roomsRef.child('$roomId/playbackState').update(updates);

    // Update member's lastSeen
    await _roomsRef.child('$roomId/members/$uid/lastSeen').set(
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Set up Firebase onDisconnect hooks.
  /// When a user disconnects unexpectedly, this will:
  /// 1. Set their isOnline to false
  /// 2. Pause playback for the room
  Future<void> _setupDisconnectHooks(String roomId, String uid) async {
    final memberRef = _roomsRef.child('$roomId/members/$uid');
    final playbackRef = _roomsRef.child('$roomId/playbackState');

    // When connection drops, set member offline
    await memberRef.child('isOnline').onDisconnect().set(false);
    await memberRef.child('lastSeen').onDisconnect().set(
      ServerValue.timestamp,
    );

    // Pause playback on disconnect
    await playbackRef.onDisconnect().update({
      'isPlaying': false,
      'updatedBy': uid,
      'updatedAt': ServerValue.timestamp,
      'reason': 'disconnect',
    });
  }

  /// Mark a member as online (used for reconnection).
  Future<void> setMemberOnline(String roomId) async {
    final uid = AuthService.currentUid;
    if (uid.isEmpty) return;

    await _roomsRef.child('$roomId/members/$uid').update({
      'isOnline': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });

    // Re-setup disconnect hooks
    await _setupDisconnectHooks(roomId, uid);
  }

  /// Check if a room exists by code.
  Future<bool> roomExistsByCode(String roomCode) async {
    final snapshot = await _codesRef.child(roomCode.toUpperCase()).get();
    return snapshot.exists;
  }
}
