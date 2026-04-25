import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A full-screen overlay that shows a countdown (3...2...1) 
/// before a synchronized play or pause action.
class SyncCountdownOverlay extends StatefulWidget {
  final bool willPlay; // true = countdown to PLAY, false = countdown to PAUSE
  final String triggeredBy; // display name of who triggered
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const SyncCountdownOverlay({
    super.key,
    required this.willPlay,
    required this.triggeredBy,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<SyncCountdownOverlay> createState() => _SyncCountdownOverlayState();
}

class _SyncCountdownOverlayState extends State<SyncCountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  Timer? _timer;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 1.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _scaleCtrl.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _count--;
      });
      if (_count > 0) {
        _scaleCtrl.reset();
        _scaleCtrl.forward();
      } else {
        timer.cancel();
        // Auto-dismiss after a short delay to show the "NOW!" state
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.willPlay ? 'PLAY' : 'PAUSE';
    final icon = widget.willPlay ? Icons.play_arrow_rounded : Icons.pause_rounded;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Who triggered
              Text(
                '${widget.triggeredBy} synced $action',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Big countdown number
              if (_count > 0)
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE50914).withOpacity(0.2),
                        border: Border.all(
                          color: const Color(0xFFE50914),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Show action icon when countdown finishes
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, val, child) => Opacity(
                    opacity: val,
                    child: Transform.scale(scale: val, child: child),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE50914),
                    ),
                    child: Icon(icon, color: Colors.white, size: 64),
                  ),
                ),

              const SizedBox(height: 20),

              // Instruction — different text for web vs mobile
              if (_count > 0)
                Text(
                  'Get ready to $action...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                )
              else ...[
                Text(
                  kIsWeb
                      ? 'Tap the video to $action now!'
                      : '$action now!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '👆 Press play on the video player',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Text(
                'Tap anywhere to dismiss',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
