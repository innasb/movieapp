import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../cubits/call_cubit.dart';
import '../cubits/call_state.dart';

/// Floating call controls and video overlay for Watch Together.
class CallControls extends StatelessWidget {
  final String roomId;
  const CallControls({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallCubit, CallState>(
      builder: (ctx, state) {
        if (!state.isActive) return const SizedBox.shrink();

        final cubit = ctx.read<CallCubit>();

        return Positioned(
          top: 60, right: 16,
          child: Column(children: [
            // Video preview (if video call)
            if (state.callType == CallType.video || (state.status == CallStatus.connected && cubit.remoteRenderer.renderVideo))
              _videoPreview(ctx, state),
            const SizedBox(height: 8),
            // Control pill
            _controlPill(ctx, state),
          ]),
        );
      },
    );
  }

  Widget _videoPreview(BuildContext ctx, CallState state) {
    final cubit = ctx.read<CallCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Remote Video
        if (state.status == CallStatus.connected && cubit.remoteRenderer.renderVideo)
          Container(
            width: 120, height: 160,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(cubit.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
        
        // Local Video
        if (state.isCameraOn)
          Container(
            width: 120, height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE50914), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(cubit.localRenderer, mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
      ],
    );
  }

  Widget _controlPill(BuildContext ctx, CallState state) {
    final cubit = ctx.read<CallCubit>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // Duration
        if (state.status == CallStatus.connected)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(_formatDuration(state.callDuration),
              style: const TextStyle(color: Colors.white70, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ),
        // Mute toggle
        _ctrlBtn(
          icon: state.isMuted ? Icons.mic_off : Icons.mic,
          color: state.isMuted ? Colors.red : Colors.white70,
          onTap: cubit.toggleMute,
        ),
        const SizedBox(width: 8),
        // Camera toggle
        if (state.callType == CallType.video) ...[
          _ctrlBtn(
            icon: state.isCameraOn ? Icons.videocam : Icons.videocam_off,
            color: state.isCameraOn ? Colors.white70 : Colors.red,
            onTap: cubit.toggleCamera,
          ),
          const SizedBox(width: 8),
        ],
        // End call
        _ctrlBtn(
          icon: Icons.call_end,
          color: Colors.white,
          bgColor: Colors.red,
          onTap: cubit.endCall,
        ),
      ]),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required Color color,
    Color? bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor ?? Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
