import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../data/datasources/webrtc_signaling.dart';
import '../../core/utils/auth_service.dart';
import 'call_state.dart';

/// Cubit managing voice/video calls in a Watch Together room.
class CallCubit extends Cubit<CallState> {
  WebRTCSignaling? _signaling;
  Timer? _durationTimer;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  CallCubit() : super(const CallState()) {
    initRenderers();
  }

  /// Initialize renderers.
  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Start a voice call.
  Future<void> startVoiceCall(String roomId, {bool isOffer = true}) async {
    await _startCall(roomId, CallType.voice, isOffer: isOffer);
  }

  /// Start a video call.
  Future<void> startVideoCall(String roomId, {bool isOffer = true}) async {
    await _startCall(roomId, CallType.video, isOffer: isOffer);
  }

  /// Core call initiation logic.
  Future<void> _startCall(String roomId, CallType type, {bool isOffer = true}) async {
    if (state.status != CallStatus.idle && state.status != CallStatus.ended) {
      return; // Prevent multiple rapid taps
    }

    try {
      // Temporarily emit calling state to prevent rapid taps while requesting permissions
      emit(state.copyWith(
        status: CallStatus.calling,
        callType: type,
        isCameraOn: type == CallType.video,
      ));

      // Request permissions on non-web platforms (WebRTC getUserMedia handles it natively on Web)
      if (!kIsWeb) {
        final statuses = await [
          Permission.camera,
          Permission.microphone,
        ].request();

        if (statuses[Permission.microphone] != PermissionStatus.granted ||
            (type == CallType.video && statuses[Permission.camera] != PermissionStatus.granted)) {
          emit(state.copyWith(
            status: CallStatus.ended,
            error: 'Microphone or Camera permission denied.',
          ));
          return;
        }
      }

      _signaling = WebRTCSignaling(
        roomId: roomId,
        localUid: AuthService.currentUid,
      );

      // Get local media
      final localStream = await _signaling!.initLocalStream(
        audio: true,
        video: type == CallType.video,
      );
      localRenderer.srcObject = localStream;

      // Listen for remote stream
      _signaling!.onRemoteStream.listen((stream) {
        remoteRenderer.srcObject = stream;
        emit(state.copyWith(status: CallStatus.connected));
        _startDurationTimer();
      });

      // Listen for connection state
      _signaling!.onConnectionState.listen((rtcState) {
        if (rtcState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (state.status != CallStatus.connected) {
            emit(state.copyWith(status: CallStatus.connected));
            _startDurationTimer();
          }
        } else if (rtcState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                   rtcState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          endCall();
        }
      });

      // Check if an offer from the other user already exists
      final hasOffer = await _signaling!.checkIfOfferExists();

      if (hasOffer) {
        await _signaling!.createAnswer();
        emit(state.copyWith(status: CallStatus.connected));
        _startDurationTimer();
      } else {
        await _signaling!.createOffer();
      }
    } catch (e, stack) {
      print('WebRTC StartCall Error: $e');
      print(stack);
      emit(state.copyWith(
        status: CallStatus.ended,
        error: e.toString(),
      ));
    }
  }

  /// Toggle mute.
  void toggleMute() {
    final newMuted = !state.isMuted;
    _signaling?.toggleMute(newMuted);
    emit(state.copyWith(isMuted: newMuted));
  }

  /// Toggle camera.
  void toggleCamera() {
    final newCameraState = !state.isCameraOn;
    _signaling?.toggleCamera(newCameraState);
    emit(state.copyWith(isCameraOn: newCameraState));
  }

  /// End the call.
  Future<void> endCall() async {
    _durationTimer?.cancel();
    await _signaling?.hangUp();

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    emit(const CallState(status: CallStatus.ended));

    // Reset to idle after a short delay
    await Future.delayed(const Duration(seconds: 1));
    if (!isClosed) {
      emit(const CallState());
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    var seconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      if (!isClosed) {
        emit(state.copyWith(callDuration: Duration(seconds: seconds)));
      }
    });
  }

  @override
  Future<void> close() async {
    _durationTimer?.cancel();
    await _signaling?.dispose();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    return super.close();
  }
}
