import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../core/utils/config.dart';

class PlayerPage extends StatefulWidget {
  final int id; // TMDB ID
  final bool isMovie;
  final int? season;
  final int? episode;

  const PlayerPage({
    super.key, 
    required this.id, 
    this.isMovie = true,
    this.season,
    this.episode,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Domains allowed to load (the video source + its CDNs)
  static const _allowedHosts = [
    'vidsrc-embed.ru',
    'vidsrc.ru',
    'vidsrc.me',
    'vidsrc.to',
    'vidsrc.net',
    'vidsrc.in',
    'vidsrc.pm',
    'vidsrc.xyz',
    'vidsrc.stream',
    'vsembed.ru',
    'multiembed.mov',
    'embedsu.com',
    'blackvid.space',
    'vidlink.pro',
    'vidplay.online',
    'vidplay.site',
    'dokicloud.one',
    'rabbitstream.net',
    'megacloud.tv',
    'rapid-cloud.co',
  ];

  /// JS that removes common ad/popup overlays and disables window.open
  static const _adBlockScript = '''
    (function() {
      // Override window.open to block popup windows
      window.open = function() { return null; };

      // Make the page UI match a pure video player
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
        /* Hide logos, watermarks, and unnecessary UI elements */
        .jw-logo, .jw-watermark, .vjs-watermark, .vjs-logo, 
        img[src*="vidsrc"], img[src*="logo"], a[href*="vidsrc"],
        .jw-title, .vjs-title-bar, #logo, .logo {
          display: none !important;
          opacity: 0 !important;
          pointer-events: none !important;
          visibility: hidden !important;
        }
        /* Hide common popup/ad containers */
        .ad-container, .ads-container, .popup, .overlay {
          display: none !important;
        }
      `;
      document.head.appendChild(style);

      function removeAdsAndLogos() {
        const adSelectors = [
          'iframe[src*="ads"]',
          'iframe[src*="banner"]',
          'div[class*="ad-"]',
          'div[class*="ads-"]',
          'div[class*="popup"]',
          'div[class*="overlay"]',
          'div[id*="ad-"]',
          'div[id*="ads-"]',
          'div[id*="popup"]',
          'a[target="_blank"][rel*="nofollow"]'
        ];
        
        for (const sel of adSelectors) {
          document.querySelectorAll(sel).forEach(el => {
            // Don't remove the actual video player iframe
            if (el.tagName === 'IFRAME' && el.src && 
                (el.src.includes('vidsrc') || el.src.includes('embed'))) return;
            el.remove();
          });
        }
      }

      function attemptAutoPlay() {
        // Try starting video
        const videos = document.querySelectorAll('video');
        videos.forEach(v => {
          v.muted = false;
          v.play().catch(e => console.log('Autoplay error', e));
        });
        
        // Try clicking play buttons
        const playBtns = document.querySelectorAll('.jw-icon-display, .jw-icon-playback, .vjs-big-play-button');
        playBtns.forEach(b => b.click());
      }

      removeAdsAndLogos();
      setTimeout(attemptAutoPlay, 500);

      // Re-run periodically to catch dynamically injected content
      setInterval(() => {
        removeAdsAndLogos();
        attemptAutoPlay();
      }, 1000);

      // Block click-hijacking: stop clicks that try to open new tabs
      document.addEventListener('click', function(e) {
        const t = e.target.closest('a');
        if (t && t.target === '_blank') {
          e.preventDefault();
          e.stopPropagation();
        }
      }, true);
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

    final String videoUrl;
    if (widget.isMovie) {
      videoUrl = '${Config.vidsrcBaseUrl}/embed/movie?tmdb=${widget.id}';
    } else {
      videoUrl = '${Config.vidsrcBaseUrl}/embed/tv?tmdb=${widget.id}&season=${widget.season}&episode=${widget.episode}';
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

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
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
      )
      ..loadRequest(Uri.parse(videoUrl));
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
