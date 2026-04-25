import 'package:equatable/equatable.dart';

enum CallStatus { idle, calling, ringing, connected, ended }
enum CallType { voice, video }

class CallState extends Equatable {
  final CallStatus status;
  final CallType callType;
  final bool isMuted;
  final bool isCameraOn;
  final Duration callDuration;
  final String? error;

  const CallState({
    this.status = CallStatus.idle,
    this.callType = CallType.voice,
    this.isMuted = false,
    this.isCameraOn = false,
    this.callDuration = Duration.zero,
    this.error,
  });

  CallState copyWith({
    CallStatus? status,
    CallType? callType,
    bool? isMuted,
    bool? isCameraOn,
    Duration? callDuration,
    String? error,
  }) {
    return CallState(
      status: status ?? this.status,
      callType: callType ?? this.callType,
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      callDuration: callDuration ?? this.callDuration,
      error: error,
    );
  }

  bool get isActive => status == CallStatus.connected || status == CallStatus.calling || status == CallStatus.ringing;

  @override
  List<Object?> get props => [status, callType, isMuted, isCameraOn, callDuration, error];
}
