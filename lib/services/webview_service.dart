import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'app_log.dart';

class WebViewService {
  static InAppWebViewController? _controller;
  static bool _isPlaying = false;
  static String currentUrl = 'https://akashvani.gov.in/radio/live.php';
  static bool _isPageLoaded = false;
  static List<String> _channelNames = [];

  static InAppWebViewController? get controller => _controller;
  static bool get isPlaying => _isPlaying;
  static bool get isPageLoaded => _isPageLoaded;
  static List<String> get channelNames => _channelNames;

  static void setController(InAppWebViewController controller) {
    _controller = controller;
  }

  static void setPageLoaded(bool loaded) {
    _isPageLoaded = loaded;
    AppLog.log('WebView page loaded: $loaded');
  }

  static Future<void> fetchChannelNames() async {
    if (_controller == null) {
      AppLog.log('Cannot fetch channels: controller null');
      return;
    }

    if (!_isPageLoaded) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final jsCode = '''
      (function() {
        var channels = document.querySelectorAll('.selectchannel .channel-name');
        var names = [];
        for (var i = 0; i < channels.length; i++) {
          var text = channels[i].textContent || channels[i].innerText;
          if (text) names.push(text.trim());
        }
        return JSON.stringify(names);
      })();
    ''';

    try {
      final result = await _controller!.evaluateJavascript(source: jsCode);
      if (result != null && result.isNotEmpty) {
        _channelNames = List<String>.from(jsonDecode(result));
        AppLog.log('Fetched ${_channelNames.length} channels');
      }
    } catch (e) {
      AppLog.log('Error fetching channels: $e');
    }
  }

  static Future<void> clickChannel(String channelName) async {
    if (_controller == null) {
AppLog.log('Controller is null');
    await Future.delayed(const Duration(milliseconds: 500));
    if (_controller == null) {
      AppLog.log('Still null, returning');
      return;
    }
  }

  await Future.delayed(const Duration(milliseconds: 500));

  final normalizedSearch = channelName.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final noSpaceSearch = normalizedSearch.replaceAll(' ', '');

  AppLog.log('Searching for channel: "$channelName", normalized: "$normalizedSearch"');

    final jsCode = '''
      (function() {
        var channels = document.querySelectorAll('.selectchannel');
        for (var i = 0; i < channels.length; i++) {
          var nameEl = channels[i].querySelector('.channel-name');
          if (!nameEl) continue;
          
          var text = (nameEl.textContent || nameEl.innerText || '').replace(/\\s+/g, ' ').trim().toLowerCase();
          var noSpaceText = text.replaceAll(' ', '');
          var search = '$normalizedSearch'.toLowerCase().replaceAll(' ', '');
          var noSpaceSearch = search.replaceAll(' ', '');
          
          if (text.includes(search) || search.includes(text) || 
              noSpaceText.includes(noSpaceSearch) || noSpaceSearch.includes(noSpaceText)) {
            channels[i].click();
            return 'clicked:' + nameEl.textContent;
          }
        }
        
        var allDivs = document.querySelectorAll('div, li');
        for (var i = 0; i < allDivs.length; i++) {
          var text = (allDivs[i].textContent || '').replace(/\\s+/g, ' ').trim().toLowerCase();
          if (text === search || text.includes(search)) {
            allDivs[i].click();
            return 'clicked';
          }
        }
        return 'not_found';
      })();
    ''';

    try {
      final result = await _controller!.evaluateJavascript(source: jsCode);
      AppLog.log('ClickChannel result: $result');
    } catch (e) {
      AppLog.log('ClickChannel error: $e');
    }
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
    AppLog.log('TogglePlayPause result: $result, isPlaying: $_isPlaying');
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
    AppLog.log('CheckPlayingState result: $result, isPlaying: $_isPlaying');
  }
}