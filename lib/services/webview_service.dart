import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewService {
  static InAppWebViewController? _controller;
  static bool _isPlaying = false;
  static String currentUrl = 'https://akashvani.gov.in/radio/live.php';

  static InAppWebViewController? get controller => _controller;
  static bool get isPlaying => _isPlaying;

  static void setController(InAppWebViewController controller) {
    _controller = controller;
  }

  static Future<void> clickChannel(String channelName) async {
    if (_controller == null) return;

    final normalizedSearch = channelName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final noSpaceSearch = normalizedSearch.replaceAll(' ', '');
    final upperSearch = normalizedSearch.toUpperCase();

    final jsCode = '''
      (function() {
        var elements = document.querySelectorAll('a, button, li, div, span, p');
        for (var i = 0; i < elements.length; i++) {
          var text = elements[i].textContent || elements[i].innerText;
          if (text) {
            var normalizedText = text.replace(/\\s+/g, ' ').trim();
            var noSpaceText = normalizedText.replaceAll(' ', '');
            
            if (normalizedText.toLowerCase().includes('$normalizedSearch') || 
                '$normalizedSearch'.includes(normalizedText.toLowerCase()) ||
                noSpaceText.toLowerCase().includes('$noSpaceSearch') ||
                '$noSpaceSearch'.includes(noSpaceText.toLowerCase()) ||
                normalizedText.toUpperCase().includes('$upperSearch')) {
              elements[i].click();
              return 'clicked';
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