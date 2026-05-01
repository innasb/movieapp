import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/utils/config.dart';
import '../widgets/web_player.dart';

class PlayerPage extends StatefulWidget {
  final int id; // TMDB ID or MAL ID
  final bool isMovie;
  final int? season;
  final int? episode;
  final bool isAnime;
  final int? episodeNumber; // Anime episode number
  final String subOrDub; // 'sub' or 'dub'

  const PlayerPage({
    super.key, 
    required this.id, 
    this.isMovie = true,
    this.season,
    this.episode,
    this.isAnime = false,
    this.episodeNumber,
    this.subOrDub = 'sub',
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  late final String _videoUrl;

  // Domains allowed to load (the video source + its CDNs)
  static const _allowedHosts = [
    'vidlink.pro',
    'vidplay.online',
    'vidplay.site',
    'dokicloud.one',
    'rabbitstream.net',
    'megacloud.tv',
    'rapid-cloud.co',
    'multiembed.mov',
    'embedsu.com',
  ];

  /// Minimal JS to ensure the player fills the WebView cleanly.
  /// VidLink is a clean player — no aggressive ad-blocking needed.
  static const _adBlockScript = '''
    (function() {
      const style = document.createElement('style');
      style.innerHTML = `
        body, html {
          background-color: #000000 !important;
          margin: 0 !important;
          padding: 0 !important;
          width: 100% !important;
          height: 100% !important;
          overflow: hidden !important;
        }
        iframe {
          border: none !important;
          width: 100% !important;
          height: 100% !important;
          position: absolute !important;
          top: 0 !important;
          left: 0 !important;
        }
      `;
      document.head.appendChild(style);
      
      // Block popups and redirects
      window.open = function() { return null; };
      window.alert = function() {};
      window.confirm = function() { return false; };
      try { Object.freeze(window.location); } catch(e) {}
      
      // Periodic cleanup of injected ad iframes
      setInterval(function() {
        try {
          var adSelectors = ['div[style*="z-index: 9999"]', 'a[target="_blank"]'];
          adSelectors.forEach(function(sel) {
            document.querySelectorAll(sel).forEach(function(el) { if (el.tagName !== 'IFRAME') el.remove(); });
          });
        } catch(e) {}
      }, 3000);
    })();
  ''';

  bool _isAllowedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      // Allow about:blank, javascript:, data: schemes
      if (['about', 'javascript', 'data', 'blob'].contains(uri.scheme)) {
        return true;
      }
      return _allowedHosts.any(
        (allowed) => host == allowed || host.endsWith('.\$allowed'),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      if (widget.isAnime) {
        _videoUrl = '${Config.vidlinkBaseUrl}/anime/${widget.id}/${widget.episodeNumber}/${widget.subOrDub}?primaryColor=E50914&autoplay=true&fallback=true';
      } else if (widget.isMovie) {
        _videoUrl = '${Config.vidlinkBaseUrl}/movie/${widget.id}?primaryColor=E50914&autoplay=true';
      } else {
        _videoUrl = '${Config.vidlinkBaseUrl}/tv/${widget.id}/${widget.season}/${widget.episode}?primaryColor=E50914&autoplay=true&nextbutton=true';
      }
    } else {
      if (widget.isAnime) {
        _videoUrl = '${Config.vidlinkBaseUrl}/anime/${widget.id}/${widget.episodeNumber}/${widget.subOrDub}?primaryColor=E50914&autoplay=true&fallback=true';
      } else if (widget.isMovie) {
        _videoUrl = '${Config.vidlinkBaseUrl}/movie/${widget.id}?primaryColor=E50914&autoplay=true';
      } else {
        _videoUrl = '${Config.vidlinkBaseUrl}/tv/${widget.id}/${widget.season}/${widget.episode}?primaryColor=E50914&autoplay=true&nextbutton=true';
      }
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(Colors.black);
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Block navigations to ad / external domains
            if (_isAllowedUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            debugPrint('⛔ Blocked ad navigation: \${request.url}');
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            // Inject ad-blocker & UI enhancer script after every page load
            _controller.runJavaScript(_adBlockScript);
            if (_isLoading) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );
    } else {
      if (_isLoading && mounted) {
        Future.microtask(() {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    }

    if (!kIsWeb) {
      _controller.loadRequest(Uri.parse(_videoUrl));
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // Don't pop the route
    }
    return true; // Pop the route (go back to details)
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (kIsWeb)
                buildWebPlayer(_videoUrl)
              else
                WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
