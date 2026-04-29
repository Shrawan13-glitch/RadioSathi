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
        var channels = document.querySelectorAll('.selectchannel');
        for (var i = 0; i < channels.length; i++) {
          var channelDiv = channels[i].querySelector('.channel-name');
          if (channelDiv) {
            var text = channelDiv.textContent || channelDiv.innerText || '';
            var normalizedText = text.replace(/\\s+/g, ' ').trim().toLowerCase();
            var noSpaceText = normalizedText.replaceAll(' ', '');
            
            if (normalizedText.includes('$normalizedSearch') || 
                noSpaceText.includes('$noSpaceSearch') ||
                '$normalizedSearch'.includes(normalizedText)) {
              debug.log('Found channel: ' + text);
              channels[i].click();
              return 'clicked:' + text;
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
        var playIcon = document.querySelector('.play-icon');
        if (playIcon) {
          playIcon.click();
          var isPlaying = playIcon.classList.contains('icon-pause') || !playIcon.classList.contains('icon-play');
          return isPlaying ? 'playing' : 'paused';
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