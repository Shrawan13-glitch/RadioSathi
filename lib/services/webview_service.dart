import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewService {
  static InAppWebViewController? _controller;
  static bool _isPlaying = false;
  static String currentUrl = 'https://akashvani.gov.in/radio/live.php';
  static bool _isPageLoaded = false;

  static InAppWebViewController? get controller => _controller;
  static bool get isPlaying => _isPlaying;
  static bool get isPageLoaded => _isPageLoaded;

  static void setController(InAppWebViewController controller) {
    _controller = controller;
  }

  static void setPageLoaded(bool loaded) {
    _isPageLoaded = loaded;
    debugPrint('WebView page loaded: $loaded');
  }

  static Future<void> clickChannel(String channelName) async {
    if (_controller == null) {
      debugPrint('Controller is null');
      return;
    }

    if (!_isPageLoaded) {
      debugPrint('Page not loaded yet, waiting...');
      await Future.delayed(const Duration(seconds: 2));
    }

    final normalizedSearch = channelName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final noSpaceSearch = normalizedSearch.replaceAll(' ', '');

    debugPrint('Searching for channel: $channelName, normalized: $normalizedSearch');

    final jsCode = '''
      (function() {
        var found = false;
        var elements = document.querySelectorAll('a, button, li, div, span, p, td, tr, table');
        for (var i = 0; i < elements.length; i++) {
          var el = elements[i];
          var text = el.textContent || el.innerText || '';
          if (text) {
            var normalizedText = text.replace(/\\s+/g, ' ').trim().toLowerCase();
            var noSpaceText = normalizedText.replaceAll(' ', '');
            
            if (normalizedText.includes('$normalizedSearch') || 
                noSpaceText.includes('$noSpaceSearch') ||
                '$normalizedSearch'.includes(normalizedText)) {
              debug.log('Found element: ' + text.substring(0, 50));
              el.click();
              found = true;
              return 'clicked:' + text.substring(0, 30);
            }
          }
        }
        return 'not_found';
      })();
    ''';

    final result = await _controller!.evaluateJavascript(source: jsCode);
    debugPrint('ClickChannel result: $result');
  }

  static Future<void> togglePlayPause() async {
    if (_controller == null) return;

    final jsCode = '''
      (function() {
        var playButton = document.querySelector('.play-pause-btn, #playBtn, .play-button, button.play, [class*="play-pause"], [id*="play"]');
        if (playButton) {
          playButton.click();
          return 'clicked';
        }
        var audio = document.querySelector('audio');
        if (audio) {
          if (audio.paused) {
            audio.play();
          } else {
            audio.pause();
          }
          return audio.paused ? 'paused' : 'playing';
        }
        return 'not_found';
      })();
    ''';

    final result = await _controller!.evaluateJavascript(source: jsCode);
    _isPlaying = result == 'playing';
    debugPrint('TogglePlayPause result: $result, isPlaying: $_isPlaying');
  }

  static Future<void> checkPlayingState() async {
    if (_controller == null) return;

    final jsCode = '''
      (function() {
        var audio = document.querySelector('audio');
        if (audio) {
          return !audio.paused;
        }
        return null;
      })();
    ''';

    final result = await _controller!.evaluateJavascript(source: jsCode);
    _isPlaying = result == true;
    debugPrint('CheckPlayingState result: $result, isPlaying: $_isPlaying');
  }
}