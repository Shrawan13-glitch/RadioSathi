import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsLanguage { english, marathi, hindi }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  TtsLanguage _currentLanguage = TtsLanguage.marathi;
  bool _hasWelcomed = false;

  static const String _languageKey = 'preferred_language';

  static const Map<TtsLanguage, Map<String, String>> _languageConfigs = {
    TtsLanguage.english: {
      'tts': 'en-US',
      'stt': 'en_US',
      'display': 'English',
    },
    TtsLanguage.marathi: {
      'tts': 'mr-IN',
      'stt': 'mr_IN',
      'display': 'Marathi',
    },
    TtsLanguage.hindi: {
      'tts': 'hi-IN',
      'stt': 'hi_IN',
      'display': 'Hindi',
    },
  };

  static const Map<TtsLanguage, Map<String, String>> _feedbackMessages = {
    TtsLanguage.marathi: {
      'appStarted': 'नमस्कार. रेडिओ साथी सुरू झाले आहे. तुम्हाला काय ऐकायचे आहे ते बोला. बोलण्यासाठी स्क्रीनवर दोनदा टॅप करा.',
      'listening': 'मी ऐकत आहे. बोला.',
      'listeningStopped': 'ऐकणे थांबवले.',
      'searching': 'शोधत आहे.',
      'foundResults': 'शोध पूर्ण झाला.',
      'playingFirst': 'पहिले परिणाम वाजवत आहे.',
      'playingNext': 'पुढचे गाणे लावत आहे.',
      'paused': 'थांबवले आहे.',
      'resumed': 'पुन्हा सुरू केले आहे.',
      'stopped': 'थांबले आहे.',
      'noResults': 'काही परिणाम सापडले नाहीत.',
      'networkError': 'इंटरनेट उपलब्ध नाही. कृपया कनेक्शन तपासा.',
      'notUnderstood': 'मला नीट ऐकू आले नाही. कृपया पुन्हा बोला.',
      'error': 'काही त्रुटी झाली. पुन्हा प्रयत्न करा.',
      'commandMode': 'कमांड मोड सुरू.',
      'youtubeMode': 'यूट्यूब मोड सुरू.',
      'channelPlaying': 'वाजवत आहे',
      'playbackError': 'वाजवण्यात अडबण आली.',
      'help': 'रेडिओ साथी वापरणे सोपे आहे. बोलण्यासाठी स्क्रीनवर दोनदा टॅप करा. थांबवण्यासाठी स्क्रीनवर लांब दाबा. पुढचे ऐकण्यासाठी उजवीकडे स्वाइप करा. मागचे ऐकण्यासाठी डावीकडे स्वाइप करा. तुम्ही गाणे, भजन, बातमी किंवा कलाकाराचे नाव बोलू शकता.',
      'recentPlaying': 'अलीकडे ऐकलेले वाजवत आहे.',
      'recentEmpty': 'अलीकडे ऐकलेले काही उपलब्ध नाही.',
      'speechUnavailable': 'बोलणे ऐकणे सुरू करता येत नाही. पुन्हा प्रयत्न करा.',
      'micPermissionDenied': 'मायक्रोफोनची परवानगी दिलेली नाही. सेटिंग्जमध्ये परवानगी द्या.',
      'noSearchResult': 'मला काही परिणाम सापडले नाहीत. कृपया दुसरे नाव बोला.',
      'playbackFailed': 'हे वाजवता येत नाही. पुढचा परिणाम वापरून पाहत आहे.',
      'youtubeExtractionFailed': 'व्हिडिओ लिंक मिळत नाही. पुढचा परिणाम वापरत आहे.',
      'ttsUnavailable': 'बोलण्याची सेवा उपलब्ध नाही.',
      'retrying': 'पुन्हा प्रयत्न करत आहे.',
      'tryNextResult': 'पुढचा परिणाम वापरत आहे.',
    },
    TtsLanguage.hindi: {
      'appStarted': 'नमस्ते। रेडियो साथी शुरू हो गया है। बताइए क्या सुनना चाहते हैं। बोलने के लिए स्क्रीन पर दो बार टैप करें।',
      'listening': 'मैं सुन रहा हूँ। बोलिए।',
      'listeningStopped': 'सुनना बंद कर दिया।',
      'searching': 'खोज रहा हूँ।',
      'foundResults': 'खोज पूरी हुई।',
      'playingFirst': 'पहला परिणाम बजा रहा हूँ।',
      'playingNext': 'अगला गाना लगा रहा हूँ।',
      'paused': 'रोक दिया है।',
      'resumed': 'फिर से शुरू किया है।',
      'stopped': 'बंद कर दिया है।',
      'noResults': 'कोई परिणाम नहीं मिला।',
      'networkError': 'इंटरनेट उपलब्ध नहीं है। कृपय��� कनेक्शन जांचें।',
      'notUnderstood': 'मुझे सही नहीं सुनाई दिया। कृपया फिर से बोलें।',
      'error': 'कोई त्रुटि हुई। फिर से प्रयास करें।',
      'commandMode': 'कमांड मोड शुरू।',
      'youtubeMode': 'यूट्यूब मोड शुरू।',
      'channelPlaying': 'बजा रहा है',
      'playbackError': 'बजाने में समस्या आई।',
      'help': 'रेडियो साथी बहुत आसान है। बोलने के लिए स्क्रीन पर दो बार टैप करें। रोकने के लिए स्क्रीन पर देर तक दबाएं। आगे के गाने के लिए दाएं स्वाइप करें। पिछले गाने के लिए बाएं स्वाइप करें। आप गाना, भजन, खबर या कलाकार का नाम बोल सकते हैं।',
      'recentPlaying': 'हाल ही में सुने गाने बजा रहे हैं।',
      'recentEmpty': 'हाल ही में सुने गाने नहीं मिले।',
      'speechUnavailable': 'बोलना सुनना शुरू नहीं हो रहा। फिर से प्रयास करें।',
      'micPermissionDenied': 'माइक की अनुमति नहीं दी गई। सेटिंग्स में अनुमति दें।',
      'noSearchResult': 'कोई परिणाम नहीं मिला। कृपया दूसरा नाम बोलें।',
      'playbackFailed': 'यह नहीं बज रहा। अगला परिणाम आजमा रहा हूँ।',
      'youtubeExtractionFailed': 'वीडियो लिंक नहीं मिला। अगला परिणाम आजमा रहा हूँ।',
      'ttsUnavailable': 'बोलने की सेवा उपलब्ध नहीं है।',
      'retrying': 'फिर से प्रयास कर रहा हूँ।',
      'tryNextResult': 'अगला परिणाम आजमा रहा हूँ।',
    },
    TtsLanguage.english: {
      'appStarted': 'Namaskar. Radio Sathi has started. Tell me what you want to listen. Double tap the screen to speak.',
      'listening': 'I am listening. Speak.',
      'listeningStopped': 'Listening stopped.',
      'searching': 'Searching.',
      'foundResults': 'Search complete.',
      'playingFirst': 'Playing first result.',
      'playingNext': 'Playing next.',
      'paused': 'Paused.',
      'resumed': 'Resumed.',
      'stopped': 'Stopped.',
      'noResults': 'No results found.',
      'networkError': 'No internet connection. Please check your connection.',
      'notUnderstood': 'I did not understand. Please speak again.',
      'error': 'An error occurred. Please try again.',
      'commandMode': 'Command mode started.',
      'youtubeMode': 'YouTube mode started.',
      'channelPlaying': 'Playing',
      'playbackError': 'Could not play the content.',
      'help': 'Radio Sathi is easy to use. Double tap the screen to speak. Long press to stop. Swipe right for next. Swipe left for previous. You can say song name, bhajan, news, or artist name.',
      'recentPlaying': 'Playing recently played.',
      'recentEmpty': 'No recently played items found.',
      'speechUnavailable': 'Speech recognition not available. Try again.',
      'micPermissionDenied': 'Microphone permission denied. Allow in settings.',
      'noSearchResult': 'No results found. Try a different name.',
      'playbackFailed': 'Cannot play this. Trying next result.',
      'youtubeExtractionFailed': 'Video link not found. Trying next.',
      'ttsUnavailable': 'Text-to-speech not available.',
      'retrying': 'Retrying...',
      'tryNextResult': 'Trying next result.',
    },
  };

  String get currentLanguageCode => _languageConfigs[_currentLanguage]!['tts']!;
  String get currentLocaleId => _languageConfigs[_currentLanguage]!['stt']!;
  String get currentDisplayName => _languageConfigs[_currentLanguage]!['display']!;
  TtsLanguage get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  String get welcomeMessage => _feedbackMessages[_currentLanguage]!['appStarted']!;

  Future<void> init() async {
    if (_isInitialized) return;

    await _loadSavedLanguage();
    await _configureTts();
    _isInitialized = true;
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_languageKey);
      if (savedLang != null) {
        _currentLanguage = TtsLanguage.values.firstWhere(
          (e) => e.name == savedLang,
          orElse: () => TtsLanguage.marathi,
        );
      }
    } catch (e) {
      _currentLanguage = TtsLanguage.marathi;
    }
  }

  Future<void> _configureTts() async {
    await _flutterTts.setLanguage(currentLanguageCode);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      // Callback when speech completes
    });
  }

  Future<void> setLanguage(TtsLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    await _configureTts();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.name);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isInitialized) {
      await init();
    }
    if (interrupt) {
      await _flutterTts.stop();
    }
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> speakWelcome() async {
    if (_hasWelcomed) return;
    _hasWelcomed = true;
    await speak(welcomeMessage);
  }

  void resetWelcomeFlag() {
    _hasWelcomed = false;
  }

  String _msg(String key) => _feedbackMessages[_currentLanguage]![key]!;

  Future<void> announceAppStarted() => speak(welcomeMessage);

  Future<void> announceListening() => speak(_msg('listening'), interrupt: true);

  Future<void> announceListeningStopped() => speak(_msg('listeningStopped'));

  Future<void> announceSearching() => speak(_msg('searching'), interrupt: true);

  Future<void> announceFoundResults() => speak(_msg('foundResults'));

  Future<void> announcePlayingFirst() => speak(_msg('playingFirst'));

  Future<void> announcePlayingNext() => speak(_msg('playingNext'));

  Future<void> announcePaused() => speak(_msg('paused'));

  Future<void> announceResumed() => speak(_msg('resumed'));

  Future<void> announceStopped() => speak(_msg('stopped'));

  Future<void> announceNoResults() => speak(_msg('noResults'));

  Future<void> announceNetworkError() => speak(_msg('networkError'));

  Future<void> announceNotUnderstood() => speak(_msg('notUnderstood'));

  Future<void> announceError() => speak(_msg('error'));

  Future<void> announceHelp() => speak(_msg('help'));

  Future<void> announceRecentPlaying() => speak(_msg('recentPlaying'));

  Future<void> announceRecentEmpty() => speak(_msg('recentEmpty'));

  Future<void> announceSpeechUnavailable() => speak(_msg('speechUnavailable'));

  Future<void> announceMicPermissionDenied() => speak(_msg('micPermissionDenied'));

  Future<void> announceNoSearchResult() => speak(_msg('noSearchResult'));

  Future<void> announcePlaybackFailed() => speak(_msg('playbackFailed'));

  Future<void> announceYoutubeExtractionFailed() => speak(_msg('youtubeExtractionFailed'));

  Future<void> announceTtsUnavailable() async {
    try {
      await speak(_msg('ttsUnavailable'));
    } catch (e) {
      // Last resort - if TTS is completely unavailable
    }
  }

  Future<void> announceRetrying() => speak(_msg('retrying'));

  Future<void> announceTryNextResult() => speak(_msg('tryNextResult'));

  Future<void> announceCommandMode() => speak(_msg('commandMode'));

  Future<void> announceYoutubeMode() => speak(_msg('youtubeMode'));

  Future<void> announceChannelPlaying(String channelName) =>
      speak('${_msg('channelPlaying')} $channelName');

  Future<void> announcePlaybackError() => speak(_msg('playbackError'));

  static List<Map<String, String>> get availableLanguages {
    return TtsLanguage.values.map((lang) => {
      'code': _languageConfigs[lang]!['tts']!,
      'display': _languageConfigs[lang]!['display']!,
      'locale': _languageConfigs[lang]!['stt']!,
    }).toList();
  }
}