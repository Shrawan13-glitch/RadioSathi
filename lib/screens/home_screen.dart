import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/hive_service.dart';
import '../services/webview_service.dart';
import '../services/youtube_service.dart';
import '../services/audio_player_service.dart';
import '../services/app_log.dart';
import 'settings_screen.dart';

enum AppMode { radio, youtube }

class YouTubeItem {
  final String id;
  final String title;
  final String thumbnail;
  final String url;

  YouTubeItem({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.url,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isListening = false;
  bool _isWebViewVisible = false;
  
  AppMode _currentMode = AppMode.radio;
  late AnimationController _modeAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _appBarColorAnimation;
  late Animation<Color?> _containerColorAnimation;
  late Animation<Color?> _accentColorAnimation;
  
  bool _isSearching = false;
  bool _isLoadingStream = false;
  List<YouTubeItem> _searchResults = [];
  YouTubeItem? _currentVideo;
  bool _isYouTubePlaying = false;

  final Color _radioBackground = const Color(0xFF1A1A2E);
  final Color _radioAppBar = const Color(0xFF16213E);
  final Color _radioContainer = const Color(0xFF16213E);
  final Color _radioAccent = Colors.deepPurple;

  final Color _youtubeBackground = const Color(0xFF1A1A1A);
  final Color _youtubeAppBar = const Color(0xFF212121);
  final Color _youtubeContainer = const Color(0xFF2D2D2D);
  final Color _youtubeAccent = Colors.red;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initSpeech();
    _initTts();
  }

  void _initAnimation() {
    _modeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _backgroundColorAnimation = ColorTween(
      begin: _radioBackground,
      end: _youtubeBackground,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _appBarColorAnimation = ColorTween(
      begin: _radioAppBar,
      end: _youtubeAppBar,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _containerColorAnimation = ColorTween(
      begin: _radioContainer,
      end: _youtubeContainer,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _accentColorAnimation = ColorTween(
      begin: _radioAccent,
      end: _youtubeAccent,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _switchToYouTubeMode() async {
    await _flutterTts.speak('YouTube mode activated');
    setState(() {
      _currentMode = AppMode.youtube;
    });
    _modeAnimationController.forward();
  }

  void _switchToRadioMode() async {
    await _audioPlayer.pause();
    await _flutterTts.speak('Radio mode activated');
    setState(() {
      _currentMode = AppMode.radio;
      _currentVideo = null;
      _isYouTubePlaying = false;
      _searchResults = [];
    });
    _modeAnimationController.reverse();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _startListening() async {
    if (_speechEnabled) {
      setState(() {
        _recognizedText = '';
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
          if (result.finalResult) {
            _checkCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _checkCommand(String spokenText) async {
    final lowerText = spokenText.toLowerCase();
    
    if (lowerText.contains('youtube on') || lowerText.contains('youtube mode')) {
      _switchToYouTubeMode();
      return;
    }
    
    if (lowerText.contains('radio on') || lowerText.contains('akashwani on') || lowerText.contains('radio mode')) {
      _switchToRadioMode();
      return;
    }

    if (_currentMode == AppMode.youtube) {
      if (lowerText.contains('play') || lowerText.contains('search')) {
        final query = lowerText
            .replaceAll('play', '')
            .replaceAll('search', '')
            .replaceAll('youtube', '')
            .trim();
        if (query.isNotEmpty) {
          _searchYouTube(query);
        }
        return;
      }
      
      if (lowerText.contains('stop') || lowerText.contains('pause')) {
        _toggleYouTubePlayPause();
        return;
      }
      
      if (lowerText.contains('next') || lowerText.contains('skip')) {
        _playNextVideo();
        return;
      }
      
      return;
    }

    final command = HiveService.findCommandByStartCommand(spokenText);
    if (command != null) {
      await _flutterTts.speak('Playing ${command.channelName}');
      AppLog.log('Executing command for: ${command.channelName}');
      await WebViewService.clickChannel(command.channelName);
      setState(() {
        _recognizedText = '';
      });
    }
  }

  Future<void> _searchYouTube(String query) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    
    await _flutterTts.speak('Searching for $query');
    
    final results = await YouTubeService().search(query);
    
    setState(() {
      _searchResults = results.map((r) => YouTubeItem(
        id: r.id,
        title: r.title,
        thumbnail: r.thumbnail,
        url: r.url,
      )).toList();
      _isSearching = false;
    });
    
    if (_searchResults.isNotEmpty) {
      await _playVideo(_searchResults.first);
    }
  }

  Future<void> _playVideo(YouTubeItem video) async {
    setState(() {
      _isLoadingStream = true;
      _currentVideo = video;
    });
    
    final videoId = video.id;
    final streamInfo = await YouTubeService().getStreamUrl(videoId);
    
    if (streamInfo != null) {
      await _audioPlayer.setUrl(streamInfo.url);
      await _audioPlayer.play();
      
      await _flutterTts.speak('Now playing ${video.title}');
      
      setState(() {
        _isLoadingStream = false;
        _isYouTubePlaying = true;
      });
    } else {
      setState(() {
        _isLoadingStream = false;
      });
      await _flutterTts.speak('Could not load the video');
    }
  }

  void _toggleYouTubePlayPause() async {
    if (_isYouTubePlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isYouTubePlaying = false;
      });
    } else {
      await _audioPlayer.play();
      setState(() {
        _isYouTubePlaying = true;
      });
    }
  }

  void _playNextVideo() {
    if (_searchResults.isEmpty) return;
    
    final currentIndex = _searchResults.indexWhere((v) => v.id == _currentVideo?.id);
    if (currentIndex < _searchResults.length - 1) {
      _playVideo(_searchResults[currentIndex + 1]);
    }
  }

  void _playPreviousVideo() {
    if (_searchResults.isEmpty) return;
    
    final currentIndex = _searchResults.indexWhere((v) => v.id == _currentVideo?.id);
    if (currentIndex > 0) {
      _playVideo(_searchResults[currentIndex - 1]);
    }
  }

  void _toggleWebView() async {
    setState(() {
      _isWebViewVisible = !_isWebViewVisible;
    });
  }

  void _togglePlayPause() async {
    await WebViewService.togglePlayPause();
    setState(() {});
  }

  Color get _backgroundColor => _backgroundColorAnimation.value ?? _radioBackground;
  Color get _appBarColor => _appBarColorAnimation.value ?? _radioAppBar;
  Color get _containerColor => _containerColorAnimation.value ?? _radioContainer;
  Color get _accentColor => _accentColorAnimation.value ?? _radioAccent;

  @override
  void dispose() {
    _modeAnimationController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _modeAnimationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 40),
                  Text(
                    'Tap the mic and speak',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: _currentMode == AppMode.radio 
                        ? _buildRadioContent()
                        : _buildYouTubeContent(),
                  ),
                  const SizedBox(height: 40),
                  _buildControlButtons(),
                  const SizedBox(height: 20),
                ],
              ),
              _buildWebViewOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarColor,
      elevation: 0,
      centerTitle: true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentMode == AppMode.radio ? Icons.radio : Icons.play_circle_fill,
              color: _accentColor,
              key: ValueKey(_currentMode),
            ),
            const SizedBox(width: 8),
            Text(
              _currentMode == AppMode.radio ? 'Radio Sathi' : 'YouTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleWebView,
          icon: Icon(
            _isWebViewVisible ? Icons.close : Icons.web,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRadioContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Text(
          _recognizedText.isEmpty
              ? 'Your speech will appear here...'
              : _recognizedText,
          style: TextStyle(
            color: _recognizedText.isEmpty ? Colors.white30 : Colors.white,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeContent() {
    if (_isSearching) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _accentColor),
              const SizedBox(height: 20),
              Text(
                'Searching...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingStream) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _accentColor),
              const SizedBox(height: 20),
              Text(
                'Loading stream...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recognizedText.isEmpty
                ? 'Say "play [song name]" to search and play'
                : _recognizedText,
            style: TextStyle(
              color: _recognizedText.isEmpty ? Colors.white30 : Colors.white,
              fontSize: 18,
              height: 1.5,
            ),
          ),
          if (_currentVideo != null) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Text(
              'Now Playing',
              style: TextStyle(color: _accentColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentVideo!.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Search Results',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: video.thumbnail.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              video.thumbnail,
                              width: 60,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 40,
                                color: Colors.grey,
                                child: const Icon(Icons.music_video, color: Colors.white54),
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 40,
                            color: Colors.grey,
                            child: const Icon(Icons.music_video, color: Colors.white54),
                          ),
                    title: Text(
                      video.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _playVideo(video),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isListening ? 100 : 80,
            height: _isListening ? 100 : 80,
            decoration: BoxDecoration(
              color: _isListening ? Colors.red : _accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isListening
                      ? Colors.red.withValues(alpha: 0.5)
                      : _accentColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: _isListening ? 50 : 40,
            ),
          ),
        ),
        if (_currentMode == AppMode.radio) ...[
          const SizedBox(width: 40),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
        ],
        if (_currentMode == AppMode.youtube && _currentVideo != null) ...[
          const SizedBox(width: 40),
          _buildYouTubeControls(),
        ],
      ],
    );
  }

  Widget _buildYouTubeControls() {
    return Row(
      children: [
        GestureDetector(
          onTap: _playPreviousVideo,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _containerColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.skip_previous,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _toggleYouTubePlayPause,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isYouTubePlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _playNextVideo,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _containerColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.skip_next,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebViewOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isWebViewVisible,
        child: Opacity(
          opacity: _isWebViewVisible ? 1.0 : 0.0,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(WebViewService.currentUrl),
                  ),
                  onWebViewCreated: (controller) {
                    WebViewService.setController(controller);
                    Future.delayed(const Duration(seconds: 2), () {
                      WebViewService.warmUpWebView();
                    });
                  },
                  onLoadStop: (controller, url) {
                    WebViewService.setPageLoaded(true);
                  },
                  initialSettings: InAppWebViewSettings(
                    useWideViewPort: true,
                    javaScriptEnabled: true,
                  ),
                ),
                if (_isWebViewVisible)
                  Positioned(
                    top: 40,
                    right: 10,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: _toggleWebView,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}