import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/utils/config.dart';
import '../../core/utils/auth_service.dart';
import '../../data/datasources/room_remote_data_source.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../cubits/watch_room_cubit.dart';
import '../cubits/watch_room_state.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_state.dart';
import '../cubits/call_cubit.dart';
import '../cubits/call_state.dart';
import '../widgets/chat_panel.dart';
import '../widgets/call_controls.dart';
import '../widgets/disconnect_overlay.dart';
import '../widgets/web_player.dart';

class WatchRoomPage extends StatefulWidget {
  final String roomId;
  const WatchRoomPage({super.key, required this.roomId});

  @override
  State<WatchRoomPage> createState() => _WatchRoomPageState();
}

class _WatchRoomPageState extends State<WatchRoomPage> {
  late WebViewController _webCtrl;
  bool _isLoading = true;
  bool _chatVisible = false;
  bool _showRoomCode = true;

  // Sync tracking
  bool _lastKnownIsPlaying = false;
  String _lastKnownUpdatedBy = '';
  bool _syncWillPlay = false;
  String _syncTriggeredBy = '';

  static const _allowedHosts = [
    'vidlink.pro', 'vidplay.online', 'vidplay.site',
    'dokicloud.one', 'rabbitstream.net', 'megacloud.tv',
    'rapid-cloud.co', 'multiembed.mov', 'embedsu.com',
  ];

  bool _isAllowedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (['about', 'javascript', 'data', 'blob'].contains(uri.scheme)) return true;
      return _allowedHosts.any((h) => uri.host == h || uri.host.endsWith('.$h'));
    } catch (_) { return false; }
  }

  void _initWebView(String videoUrl) {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webCtrl = WebViewController.fromPlatformCreationParams(params);

    if (_webCtrl.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_webCtrl.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    if (!kIsWeb) {
      _webCtrl.setJavaScriptMode(JavaScriptMode.unrestricted);
      _webCtrl.setBackgroundColor(Colors.black);
      _webCtrl.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          if (_isAllowedUrl(req.url)) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
        onPageFinished: (_) {
          _webCtrl.runJavaScript(_playerCss);
          if (_isLoading && mounted) setState(() => _isLoading = false);
        },

      ));
    } else {
      if (_isLoading && mounted) {
        Future.microtask(() {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    }

    _webCtrl.loadRequest(Uri.parse(videoUrl));
  }

  static const _playerCss = '''
    (function() {
      const s = document.createElement('style');
      s.innerHTML = \`body,html{background:#000!important;margin:0!important;padding:0!important;
        width:100%!important;height:100%!important;overflow:hidden!important}
        iframe{border:none!important;width:100%!important;height:100%!important;
        position:absolute!important;top:0!important;left:0!important}\`;
      document.head.appendChild(s);
    })();
  ''';

  String _buildVideoUrl(WatchRoomActive state) {
    final room = state.room;
    if (room.contentType == 'anime') {
      return '${Config.vidlinkBaseUrl}/anime/${room.contentId}/${room.episode ?? 1}/${room.subOrDub ?? "sub"}?primaryColor=E50914&autoplay=true&fallback=true';
    } else if (room.contentType == 'movie') {
      return '${Config.vidlinkBaseUrl}/movie/${room.contentId}?primaryColor=E50914&autoplay=true';
    } else {
      return '${Config.vidlinkBaseUrl}/tv/${room.contentId}/${room.season ?? 1}/${room.episode ?? 1}?primaryColor=E50914&autoplay=true&nextbutton=true';
    }
  }

  /// Called when the sync state changes from Firebase (another user triggered it).
  void _onSyncStateChanged(WatchRoomActive state) {
    final ps = state.room.playbackState;
    final myUid = AuthService.currentUid;

    // Only react if someone else changed the state
    if (ps.updatedBy != myUid &&
        (ps.isPlaying != _lastKnownIsPlaying || ps.updatedBy != _lastKnownUpdatedBy)) {
      // Find who triggered
      final member = state.room.members[ps.updatedBy];
      final triggerName = member?.displayName ?? 'Someone';

      // Immediately execute play/pause on the local player
      _syncWillPlay = ps.isPlaying;
      _syncTriggeredBy = triggerName;
      _executePlayPause(ps.isPlaying);

      // Show a brief notification
      if (mounted) {
        final action = ps.isPlaying ? '▶ Play' : '⏸ Pause';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ps.isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: Colors.white, size: 20,
                ),
                const SizedBox(width: 8),
                Text('$triggerName synced $action',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: const Color(0xFFE50914),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
      }
    }

    _lastKnownIsPlaying = ps.isPlaying;
    _lastKnownUpdatedBy = ps.updatedBy;
  }

  /// Called when the local user taps Play/Pause sync.
  void _onLocalSyncTap(BuildContext ctx, WatchRoomActive state) {
    final newIsPlaying = !state.room.playbackState.isPlaying;
    
    // Update Firebase — this will notify all other users
    ctx.read<WatchRoomCubit>().updatePlayback(isPlaying: newIsPlaying);

    // Immediately execute locally too
    _executePlayPause(newIsPlaying);
  }

  /// Execute the actual play/pause on the video player.
  void _executePlayPause(bool shouldPlay) {
    final command = shouldPlay ? 'play' : 'pause';

    if (kIsWeb) {
      // Web: send postMessage command to the wrapper iframe
      sendPlayerCommand(command);
    } else if (!_isLoading) {
      // Mobile: directly control the video via JavaScript injection
      _webCtrl.runJavaScript('''
        (function() {
          var action = "$command";
          // 1. Try top-level video
          var videos = document.querySelectorAll('video');
          for (var i = 0; i < videos.length; i++) {
            action === 'play' ? videos[i].play() : videos[i].pause();
          }
          // 2. Try inside iframes (same-origin)
          var frames = document.querySelectorAll('iframe');
          for (var j = 0; j < frames.length; j++) {
            try {
              var fv = frames[j].contentDocument.querySelectorAll('video');
              for (var k = 0; k < fv.length; k++) {
                action === 'play' ? fv[k].play() : fv[k].pause();
              }
              var nf = frames[j].contentDocument.querySelectorAll('iframe');
              for (var n = 0; n < nf.length; n++) {
                try {
                  var nv = nf[n].contentDocument.querySelectorAll('video');
                  for (var m = 0; m < nv.length; m++) {
                    action === 'play' ? nv[m].play() : nv[m].pause();
                  }
                } catch(e) {}
              }
            } catch(e) {}
            // Also try postMessage to the iframe
            try {
              frames[j].contentWindow.postMessage(JSON.stringify({type: action}), '*');
              frames[j].contentWindow.postMessage(JSON.stringify({event: 'command', func: action === 'play' ? 'playVideo' : 'pauseVideo'}), '*');
            } catch(e) {}
          }
          // 3. Try clicking play/pause buttons
          var selectors = ['.jw-icon-playback', '.vjs-play-control', '.plyr__control--overlaid',
            '[aria-label="Play"]', '[aria-label="Pause"]', '.play-button', '.pause-button'];
          for (var s = 0; s < selectors.length; s++) {
            try {
              var btn = document.querySelector(selectors[s]);
              if (btn) { btn.click(); break; }
            } catch(e) {}
          }
        })();
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => WatchRoomCubit(
          roomDataSource: RoomRemoteDataSource(),
          chatDataSource: ChatRemoteDataSource(),
        )..listenToExistingRoom(widget.roomId)),
        BlocProvider(create: (_) => ChatCubit(
          chatDataSource: ChatRemoteDataSource(),
        )..listenToChat(widget.roomId)),
        BlocProvider(create: (_) => CallCubit()),
      ],
      child: BlocConsumer<WatchRoomCubit, WatchRoomState>(
        listener: (ctx, state) {
          if (state is WatchRoomClosed) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.reason),
              backgroundColor: const Color(0xFFE50914),
            ));
            ctx.pop();
          }
          // React to sync changes from other users
          if (state is WatchRoomActive) {
            _onSyncStateChanged(state);
          }
        },
        builder: (ctx, state) {
          if (state is WatchRoomActive) {
            final url = _buildVideoUrl(state);
            // Init WebView once we have room data
            if (_isLoading) {
              _initWebView(url);
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                final leave = await _showLeaveDialog(ctx);
                if (leave == true && ctx.mounted) {
                  ctx.read<WatchRoomCubit>().leaveRoom();
                }
              },
              child: Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Stack(children: [
                    // Player
                    Column(children: [
                      Expanded(
                        child: kIsWeb 
                          ? buildWebPlayer(url) 
                          : WebViewWidget(controller: _webCtrl),
                      ),
                      _buildBottomBar(ctx, state, isDark),
                    ]),

                    // Loading
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.white)),

                    // Room code banner
                    if (_showRoomCode)
                      _buildRoomCodeBanner(ctx, state),

                    // Disconnect overlay
                    if (state.partnerDisconnected)
                      DisconnectOverlay(
                        message: state.disconnectMessage ?? 'Partner disconnected...',
                        onContinueAlone: () => ctx.read<WatchRoomCubit>().reconnect(),
                      ),

                    // Chat panel
                    if (_chatVisible)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        height: MediaQuery.of(ctx).size.height * 0.45,
                        child: ChatPanel(
                          roomId: widget.roomId,
                          onClose: () => setState(() => _chatVisible = false),
                        ),
                      ),
                      
                    // Call Controls
                    CallControls(roomId: widget.roomId),


                  ]),
                ),
              ),
            );
          }

          // Loading / Error states
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: state is WatchRoomError
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ctx.pop(),
                    child: const Text('Go Back'),
                  ),
                ])
              : const CircularProgressIndicator(color: Color(0xFFE50914)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext ctx, WatchRoomActive state, bool isDark) {
    final room = state.room;
    final onlineCount = room.onlineCount;
    final isPlaying = room.playbackState.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.grey[100],
        border: Border(top: BorderSide(
          color: Colors.white.withOpacity(0.08),
        )),
      ),
      child: Row(children: [
        // Online indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.green),
            ),
            const SizedBox(width: 6),
            Text('$onlineCount online',
              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        const Spacer(),

        // ── Sync Play/Pause button ──
        InkWell(
          onTap: () => _onLocalSyncTap(ctx, state),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE50914).withOpacity(0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFFE50914),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                isPlaying ? 'Pause' : 'Play',
                style: const TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.sync, color: Color(0xFFE50914), size: 14),
            ]),
          ),
        ),
        const SizedBox(width: 8),

        // Chat button
        _barButton(Icons.chat_bubble_outline, 'Chat', () {
          setState(() => _chatVisible = !_chatVisible);
        }),
        const SizedBox(width: 8),

        // Voice call
        BlocBuilder<CallCubit, CallState>(builder: (ctx, callState) {
          return _barButton(
            callState.isActive ? Icons.call_end : Icons.call,
            callState.isActive ? 'End' : 'Voice',
            () {
              if (callState.isActive) {
                ctx.read<CallCubit>().endCall();
              } else {
                ctx.read<CallCubit>().startVoiceCall(widget.roomId);
              }
            },
            color: callState.isActive ? Colors.red : null,
          );
        }),
        const SizedBox(width: 8),

        // Video call
        BlocBuilder<CallCubit, CallState>(builder: (ctx, callState) {
          return _barButton(
            Icons.videocam_outlined, 'Video',
            () => ctx.read<CallCubit>().startVideoCall(widget.roomId),
          );
        }),
        const SizedBox(width: 8),

        // Leave
        _barButton(Icons.exit_to_app, 'Leave', () async {
          final leave = await _showLeaveDialog(ctx);
          if (leave == true && ctx.mounted) {
            ctx.read<WatchRoomCubit>().leaveRoom();
          }
        }, color: const Color(0xFFE50914)),
      ]),
    );
  }

  Widget _barButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color ?? Colors.white70, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color ?? Colors.white54, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildRoomCodeBanner(BuildContext ctx, WatchRoomActive state) {
    return Positioned(
      top: 8, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C).withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE50914).withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.share, color: Color(0xFFE50914), size: 20),
          const SizedBox(width: 10),
          Text('Room: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(state.room.roomCode,
            style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.bold, letterSpacing: 4)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: state.room.roomCode));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Room code copied!'), duration: Duration(seconds: 1)),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white54, size: 18),
            onPressed: () => Share.share(
              'Join my Watchy room! Code: ${state.room.roomCode}'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            onPressed: () => setState(() => _showRoomCode = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    );
  }

  Future<bool?> _showLeaveDialog(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text('leave_room'.tr()),
        content: Text('leave_room_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('leave'.tr(), style: const TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
  }
}
