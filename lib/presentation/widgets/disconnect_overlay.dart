import 'dart:ui';
import 'package:flutter/material.dart';

/// Overlay displayed when a partner disconnects from the watch room.
class DisconnectOverlay extends StatefulWidget {
  final String message;
  final VoidCallback? onContinueAlone;

  const DisconnectOverlay({
    super.key,
    required this.message,
    this.onContinueAlone,
  });

  @override
  State<DisconnectOverlay> createState() => _DisconnectOverlayState();
}

class _DisconnectOverlayState extends State<DisconnectOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.15),
                        border: Border.all(color: Colors.orange.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.wifi_off_rounded,
                        color: Colors.orange, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(widget.message,
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Waiting for reconnection...',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 32),
                if (widget.onContinueAlone != null)
                  OutlinedButton.icon(
                    onPressed: widget.onContinueAlone,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continue watching alone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
