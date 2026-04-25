import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC signaling service using Firebase Realtime Database.
/// Handles offer/answer exchange and ICE candidate negotiation.
class WebRTCSignaling {
  final FirebaseDatabase _database;
  final String roomId;
  final String localUid;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;

  final List<StreamSubscription> _subscriptions = [];

  WebRTCSignaling({
    required this.roomId,
    required this.localUid,
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference get _signalingRef =>
      _database.ref('rooms/$roomId/signaling');

  /// ICE servers configuration for STUN/TURN.
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  /// Initialize WebRTC and get local media stream.
  Future<MediaStream> initLocalStream({
    bool audio = true,
    bool video = false,
  }) async {
    final mediaConstraints = <String, dynamic>{
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 320},
              'height': {'ideal': 240},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return _localStream!;
  }

  /// Create peer connection and set up event handlers.
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    // Add local stream tracks to connection
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Handle incoming remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('WebRTC: onTrack fired!');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      } else {
        print('WebRTC Warning: onTrack fired but event.streams is empty!');
      }
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      print('WebRTC: onAddStream fired! Got remote stream.');
      _remoteStream = stream;
      _remoteStreamController.add(_remoteStream!);
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _signalingRef.child('candidates/$localUid').push().set({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // Connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('WebRTC Connection State: $state');
      _connectionStateController.add(state);
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('WebRTC ICE Connection State: $state');
    };
  }

  /// Check if an offer from another user already exists.
  Future<bool> checkIfOfferExists() async {
    final event = await _signalingRef.child('offer').once();
    final snapshot = event.snapshot;
    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      if (data['from'] != localUid) {
        return true;
      }
    }
    return false;
  }

  /// Create an offer (caller side).
  Future<void> createOffer() async {
    print('WebRTC: Creating Offer...');
    await _createPeerConnection();

    final offerConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
    };
    final offer = await _peerConnection!.createOffer(offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    // Send offer via Firebase
    await _signalingRef.child('offer').set({
      'sdp': offer.sdp,
      'type': offer.type,
      'from': localUid,
    });
    print('WebRTC: Offer sent to Firebase.');

    // Listen for answer
    final answerSub = _signalingRef.child('answer').onValue.listen((event) async {
      if (event.snapshot.value != null) {
        print('WebRTC: Received Answer from Firebase!');
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final answer = RTCSessionDescription(
          data['sdp'] as String,
          data['type'] as String,
        );
        await _peerConnection?.setRemoteDescription(answer);
        print('WebRTC: Remote description set.');
      }
    });
    _subscriptions.add(answerSub);

    // Listen for remote ICE candidates
    _listenForRemoteCandidates();
  }

  /// Create an answer (callee side).
  Future<void> createAnswer() async {
    print('WebRTC: Creating Answer...');
    await _createPeerConnection();

    // Get the offer
    final offerEvent = await _signalingRef.child('offer').once();
    final offerSnapshot = offerEvent.snapshot;
    if (!offerSnapshot.exists) {
      print('WebRTC Error: No call offer found!');
      throw Exception('No call offer found.');
    }

    final offerData = Map<dynamic, dynamic>.from(offerSnapshot.value as Map);
    final offer = RTCSessionDescription(
      offerData['sdp'] as String,
      offerData['type'] as String,
    );

    print('WebRTC: Setting remote description from Offer...');
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer via Firebase
    await _signalingRef.child('answer').set({
      'sdp': answer.sdp,
      'type': answer.type,
      'from': localUid,
    });
    print('WebRTC: Answer sent to Firebase.');

    // Listen for remote ICE candidates
    _listenForRemoteCandidates();
  }

  /// Listen for ICE candidates from the remote peer.
  void _listenForRemoteCandidates() {
    final candidatesRef = _signalingRef.child('candidates');

    final sub = candidatesRef.onChildAdded.listen((event) {
      final senderUid = event.snapshot.key;
      if (senderUid == localUid) return; // Skip own candidates

      // Listen for individual candidates under this sender
      final candidateSub = candidatesRef.child(senderUid!).onChildAdded.listen((candidateEvent) {
        if (candidateEvent.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(candidateEvent.snapshot.value as Map);
          final candidate = RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          );
          _peerConnection?.addCandidate(candidate);
        }
      });
      _subscriptions.add(candidateSub);
    });
    _subscriptions.add(sub);
  }

  /// Toggle microphone mute.
  void toggleMute(bool muted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
  }

  /// Toggle camera on/off.
  void toggleCamera(bool enabled) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = enabled;
      }
    }
  }

  /// End the call and clean up.
  Future<void> hangUp() async {
    // Close peer connection
    await _peerConnection?.close();
    _peerConnection = null;

    // Stop local stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    // Clean up signaling data
    await _signalingRef.remove();

    // Cancel subscriptions
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await hangUp();
    await _remoteStreamController.close();
    await _connectionStateController.close();
  }

  /// Get local stream (if initialized).
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCPeerConnection? get peerConnection => _peerConnection;
}
