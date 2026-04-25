import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'package:flutter/material.dart';

/// Stores the wrapper iframe reference so we can postMessage to it.
html.IFrameElement? _wrapperIframe;

/// Set of registered view IDs to avoid duplicate registration.
final Set<String> _registeredViews = {};

Widget buildWebPlayer(String url) {
  final viewId = 'player-${url.hashCode}';

  if (!_registeredViews.contains(viewId)) {
    _registeredViews.add(viewId);

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      // Build a wrapper HTML page that:
      // 1. Blocks popup ads (overrides window.open)
      // 2. Listens for postMessage commands from the Flutter parent
      // 3. Forwards play/pause to the inner vidlink iframe
      // 4. Attempts direct video element control
      final wrapperHtml = '''
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
  #player-frame { width: 100%; height: 100%; border: none; }
</style>
</head>
<body>
<iframe id="player-frame"
  src="$url" 
  allowfullscreen 
  allow="autoplay; fullscreen; encrypted-media"
  referrerpolicy="origin"
></iframe>
<script>
  // === AD BLOCKING ===
  window.open = function() { return null; };
  window.alert = function() {};
  window.confirm = function() { return false; };
  window.prompt = function() { return null; };

  var playerFrame = document.getElementById('player-frame');

  // === RECEIVE COMMANDS FROM FLUTTER PARENT ===
  window.addEventListener('message', function(e) {
    var data = e.data;
    if (typeof data === 'string') {
      try { data = JSON.parse(data); } catch(err) { return; }
    }
    if (!data || !data.watchy) return; // Only handle our own messages

    var action = data.action; // 'play' or 'pause'
    if (action !== 'play' && action !== 'pause') return;

    // 1. Try direct video element control (if somehow same-origin)
    try {
      var videos = document.querySelectorAll('video');
      for (var i = 0; i < videos.length; i++) {
        action === 'play' ? videos[i].play() : videos[i].pause();
      }
    } catch(err) {}

    // 2. Try to access video inside the inner iframe (same-origin only)
    try {
      var innerDoc = playerFrame.contentDocument || playerFrame.contentWindow.document;
      var innerVideos = innerDoc.querySelectorAll('video');
      for (var i = 0; i < innerVideos.length; i++) {
        action === 'play' ? innerVideos[i].play() : innerVideos[i].pause();
      }
      // Also look for nested iframes inside the player
      var nestedFrames = innerDoc.querySelectorAll('iframe');
      for (var j = 0; j < nestedFrames.length; j++) {
        try {
          var nestedDoc = nestedFrames[j].contentDocument || nestedFrames[j].contentWindow.document;
          var nestedVideos = nestedDoc.querySelectorAll('video');
          for (var k = 0; k < nestedVideos.length; k++) {
            action === 'play' ? nestedVideos[k].play() : nestedVideos[k].pause();
          }
        } catch(err2) {}
      }
    } catch(err) {}

    // 3. Forward postMessage to the inner iframe (multiple formats for compatibility)
    if (playerFrame && playerFrame.contentWindow) {
      var msgs = [
        // Generic
        JSON.stringify({type: action}),
        JSON.stringify({event: action}),
        JSON.stringify({action: action}),
        JSON.stringify({command: action}),
        JSON.stringify({method: action}),
        // YouTube iframe API style
        JSON.stringify({event: 'command', func: action === 'play' ? 'playVideo' : 'pauseVideo', args: []}),
        // Vimeo style
        JSON.stringify({method: action}),
        // JW Player style  
        JSON.stringify({type: 'event', event: action === 'play' ? 'play' : 'pause'}),
        // video.js style
        JSON.stringify({type: 'player:' + action}),
      ];
      for (var i = 0; i < msgs.length; i++) {
        try {
          playerFrame.contentWindow.postMessage(msgs[i], '*');
        } catch(err) {}
      }
    }

    // 4. Also forward to ALL nested iframes we can find
    try {
      var allFrames = document.querySelectorAll('iframe');
      for (var f = 0; f < allFrames.length; f++) {
        try {
          allFrames[f].contentWindow.postMessage(JSON.stringify({type: action}), '*');
          allFrames[f].contentWindow.postMessage(JSON.stringify({event: 'command', func: action === 'play' ? 'playVideo' : 'pauseVideo'}), '*');
        } catch(err) {}
      }
    } catch(err) {}

    // 5. Try to click the play/pause button via common selectors
    try {
      var innerDoc2 = playerFrame.contentDocument || playerFrame.contentWindow.document;
      var playBtnSelectors = [
        '.jw-icon-playback', '.vjs-play-control', '.plyr__control--overlaid',
        '[aria-label="Play"]', '[aria-label="Pause"]',
        '.play-button', '.pause-button', 'button.play', 'button.pause',
        '.icon-play', '.icon-pause', '[data-plyr="play"]',
      ];
      for (var s = 0; s < playBtnSelectors.length; s++) {
        try {
          var btn = innerDoc2.querySelector(playBtnSelectors[s]);
          if (btn) { btn.click(); break; }
        } catch(err3) {}
      }
    } catch(err) {}
  });

  // === PERIODIC AD CLEANUP ===
  setInterval(function() {
    try {
      var adSelectors = [
        'div[style*="z-index: 9999"]', 'div[style*="z-index:9999"]',
        'div[style*="z-index: 99999"]', 'div[style*="z-index:99999"]',
        'a[target="_blank"]',
      ];
      adSelectors.forEach(function(sel) {
        try {
          document.querySelectorAll(sel).forEach(function(el) {
            if (el.tagName !== 'IFRAME') el.remove();
          });
        } catch(e) {}
      });
    } catch(e) {}
  }, 3000);
</script>
</body></html>
''';

      final blob = html.Blob([wrapperHtml], 'text/html');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final iframe = html.IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allowFullscreen = true
        ..src = blobUrl;

      // Store reference for postMessage communication
      _wrapperIframe = iframe;

      return iframe;
    });
  }

  return HtmlElementView(viewType: viewId);
}

/// Send a play or pause command to the wrapper iframe, which will forward it
/// to the video player inside. Call with 'play' or 'pause'.
void sendPlayerCommand(String command) {
  if (_wrapperIframe == null) return;
  try {
    final message = json.encode({'watchy': true, 'action': command});
    _wrapperIframe!.contentWindow?.postMessage(message, '*');
  } catch (_) {}
}
