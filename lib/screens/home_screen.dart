import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/hive_service.dart';
import '../services/webview_service.dart';
import '../models/command.dart';
import '../services/youtube_service.dart';
import '../services/audio_player_service.dart';
import '../services/app_log.dart';
import '../services/tts_service.dart';
import '../services/command_parser.dart';
import '../services/recently_played_service.dart';
import '../services/caregiver_settings_service.dart';
import 'settings_screen.dart';

enum AppMode { command, youtube, }

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
  final TtsService _ttsService = TtsService();
  final RecentlyPlayedService _recentService = RecentlyPlayedService();
  final AudioPlayer _beepPlayer = AudioPlayer();
  int _recentIndex = 0;
  
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isListening = false;
  bool _isWebViewVisible = false;
  
  AppMode _currentMode = AppMode.command;
  late AnimationController _modeAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _appBarColorAnimation;
  late Animation<Color?> _containerColorAnimation;
  late Animation<Color?> _accentColorAnimation;
  
  bool _isSearching = false;
  bool _isLoadingStream = false;
  String _loadingStatus = '';
  List<YouTubeItem> _searchResults = [];
  YouTubeItem? _currentVideo;
  bool _isYouTubePlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLiveStream = false;

  final Color _commandBackground = const Color(0xFF1A1A2E);
  final Color _commandAppBar = const Color(0xFF16213E);
  final Color _commandContainer = const Color(0xFF16213E);
  final Color _commandAccent = Colors.deepPurple;

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
    _initAudioPlayerListeners();
    _checkAutoListen();
  }

  Future<void> _checkAutoListen() async {
    final settings = await CaregiverSettingsService().load();
    if (settings.autoStartListening && _speechEnabled) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _startListening();
        }
      });
    }
  }

  bool _autoPlayEnabled = true;

  void _checkAutoPlay(Duration? position) {
    if (!_autoPlayEnabled) return;
    if (_searchResults.isEmpty) return;
    if (_currentMode != AppMode.youtube) return;
    if (!_isYouTubePlaying) return;
    
    final currentIndex = _searchResults.indexWhere((v) => v.id == _currentVideo?.id);
    if (currentIndex >= 0 && currentIndex < _searchResults.length - 1) {
      if (position != null && _duration.inSeconds > 0) {
        final remaining = _duration.inSeconds - position.inSeconds;
        if (remaining < 5 && remaining > 0) {
          _playNextVideo();
        }
      }
    }
  }

  void _initAudioPlayerListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position ?? Duration.zero;
        });
      }
      _checkAutoPlay(position);
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isYouTubePlaying = state.playing;
        });
      }
    });
  }

  void _initAnimation() {
    _modeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _backgroundColorAnimation = ColorTween(
      begin: _commandBackground,
      end: _youtubeBackground,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _appBarColorAnimation = ColorTween(
      begin: _commandAppBar,
      end: _youtubeAppBar,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _containerColorAnimation = ColorTween(
      begin: _commandContainer,
      end: _youtubeContainer,
    ).animate(CurvedAnimation(
      parent: _modeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _accentColorAnimation = ColorTween(
      begin: _commandAccent,
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

  void _switchToCommandMode() async {
    await _flutterTts.speak('Command mode activated. Say a command.');
    setState(() {
      _currentMode = AppMode.command;
      _currentVideo = null;
      _isYouTubePlaying = false;
      _searchResults = [];
    });
    _modeAnimationController.reverse();
  }

  void _handleCommandModeCommand(String spokenText) async {
    final command = HiveService.findCommandByStartCommand(spokenText);
    if (command != null) {
      await _executeCommand(command);
    } else {
      await _flutterTts.speak('Command not found. Say again.');
    }
  }

  Future<void> _executeCommand(Command command) async {
    switch (command.action) {
      case 'Aakashwani':
        await _flutterTts.speak('Playing ${command.channelName}');
        await WebViewService.clickChannel(command.channelName);
        break;
      case 'YouTube Search':
        if (command.youtubeQuery != null && command.youtubeQuery!.isNotEmpty) {
          await _searchYouTube(command.youtubeQuery!);
        }
        break;
      case 'YouTube Play Link':
        if (command.youtubeLink != null && command.youtubeLink!.isNotEmpty) {
          await _playYouTubeLink(command.youtubeLink!);
        }
        break;
      case 'YouTube Latest Live':
        if (command.youtubeChannelHandle != null && command.youtubeChannelHandle!.isNotEmpty) {
          await _playChannelLatestLive(command.youtubeChannelHandle!);
        }
        break;
      default:
        await WebViewService.clickChannel(command.channelName);
    }
    setState(() {
      _recognizedText = '';
    });
  }

  Future<void> _playYouTubeLink(String link) async {
    if (!mounted) return;
    
    setState(() {
      _loadingStatus = 'Searching...';
      _isSearching = true;
    });
    await _flutterTts.speak('Searching');
    
    final videos = await YouTubeService().getVideosFromLink(link);
    
    if (!mounted) return;
    
    if (videos.isNotEmpty) {
      setState(() {
        _searchResults = videos.map((v) => YouTubeItem(
          id: v.id,
          title: v.title,
          thumbnail: v.thumbnail,
          url: v.url,
        )).toList();
        _loadingStatus = 'Getting stream...';
        _isSearching = false;
      });
      
      if (_searchResults.isNotEmpty) {
        await _playVideo(_searchResults.first);
        
        if (!mounted) return;
        
        final currentVideo = _searchResults.first;
        final relatedResults = await YouTubeService().search(currentVideo.title);
        final relatedItems = relatedResults
            .where((r) => r.id != currentVideo.id)
            .take(10)
            .map((r) => YouTubeItem(
                  id: r.id,
                  title: r.title,
                  thumbnail: r.thumbnail,
                  url: r.url,
                ))
            .toList();
        
        if (relatedItems.isNotEmpty && mounted) {
          setState(() {
            _searchResults = [..._searchResults, ...relatedItems];
          });
        }
      }
    } else {
      await _flutterTts.speak('Could not load link');
      if (mounted) {
        setState(() {
          _loadingStatus = '';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _playChannelLatestLive(String channelInput) async {
    if (!mounted) return;
    
    setState(() {
      _loadingStatus = 'Finding latest live...';
      _isSearching = true;
      _searchResults = [];
    });
    
    await _flutterTts.speak('Finding latest live from channel');
    
    final videos = await YouTubeService().getChannelLatestLive(channelInput);
    
    if (!mounted) return;
    
    if (videos.isNotEmpty) {
      setState(() {
        _searchResults = videos.map((v) => YouTubeItem(
          id: v.id,
          title: v.title,
          thumbnail: v.thumbnail,
          url: v.url,
        )).toList();
        _loadingStatus = 'Getting stream...';
        _isSearching = false;
      });
      
      await _playVideo(_searchResults.first);
    } else {
      await _flutterTts.speak('Could not find any videos from this channel');
      if (mounted) {
        setState(() {
          _loadingStatus = '';
          _isSearching = false;
        });
      }
    }
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
    await _ttsService.init();
    
    final settings = await CaregiverSettingsService().load();
    final rateValue = CaregiverSettingsService().getSpeechRateValue(settings.speechRate);
    await _flutterTts.setSpeechRate(rateValue);
    
    if (!_ttsService.isInitialized) {
      await _ttsService.init();
    }
    if (settings.speakWelcome) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _ttsService.speakWelcome();
        }
      });
    }
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _playBeep(1);
      if (_currentMode == AppMode.youtube && _isYouTubePlaying) {
        await _audioPlayer.pause();
      }
      _ttsVolumeBeforeMute = _currentVolume;
      await _flutterTts.setVolume(0);
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
    await _playBeep(2);
    await _flutterTts.setVolume(_ttsVolumeBeforeMute);
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _playBeep(int count) async {
    final asset = count == 1 ? 'assets/beep.mp3' : 'assets/beep_double.mp3';
    await _beepPlayer.setAsset(asset);
    await _beepPlayer.seek(Duration.zero);
    await _beepPlayer.play();
  }

  void _checkCommand(String spokenText) async {
    final lowerText = spokenText.toLowerCase();
    
    if (lowerText.contains('youtube on') || lowerText.contains('youtube mode')) {
      _switchToYouTubeMode();
      return;
    }
    
    if (lowerText.contains('command mode') || lowerText.contains('कमांड मोड') || lowerText.contains('radio mode')) {
      _switchToCommandMode();
      return;
    }
    
    if (lowerText.contains('open settings') || lowerText.contains('settings')) {
      _openSettings();
      return;
    }

    if (_currentMode == AppMode.command) {
      if (_currentVideo != null) {
        if (lowerText.contains('next') || lowerText.contains('skip') || lowerText.contains('आगे')) {
          _playNextVideo();
          return;
        }
        if (lowerText.contains('previous') || lowerText.contains('पिछला') || lowerText.contains('पूर्व')) {
          _playPreviousVideo();
          return;
        }
        if (lowerText.contains('stop') || lowerText.contains('pause')) {
          _toggleYouTubePlayPause();
          return;
        }
      }
      _handleCommandModeCommand(spokenText);
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
      
      if (lowerText.contains('next') || lowerText.contains('skip') || lowerText.contains('आगे')) {
        _playNextVideo();
        return;
      }
      
      if (lowerText.contains('previous') || lowerText.contains('पिछला') || lowerText.contains('पूर्व')) {
        _playPreviousVideo();
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
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _loadingStatus = 'Searching...';
    });
    
    await _flutterTts.speak('Searching for $query');
    
    final results = await YouTubeService().search(query);
    
    if (!mounted) return;
    
    setState(() {
      _searchResults = results.map((r) => YouTubeItem(
        id: r.id,
        title: r.title,
        thumbnail: r.thumbnail,
        url: r.url,
      )).toList();
      _loadingStatus = 'Getting stream...';
      _isSearching = false;
    });
    await _flutterTts.speak('Loading');
    
    if (!mounted) return;
    
    if (_searchResults.isNotEmpty) {
      await _playVideo(_searchResults.first);
    } else {
      if (mounted) {
        setState(() {
          _loadingStatus = '';
        });
      }
      await _flutterTts.speak('No results found');
    }
  }

  Future<void> _playVideo(YouTubeItem video) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingStream = true;
      _currentVideo = video;
      _loadingStatus = 'Loading...';
    });
    
    final videoId = video.id;
    final streamUrl = await YouTubeService().getStreamUrl(videoId);
    
    if (!mounted) return;
    
    if (streamUrl != null) {
      await _audioPlayer.setUrl(streamUrl);
      await _audioPlayer.play();
      
      final isLive = streamUrl.contains('.m3u8');
      
      await _flutterTts.speak('Now playing ${video.title}');
      
      if (mounted) {
        setState(() {
          _isLoadingStream = false;
          _isSearching = false;
          _isYouTubePlaying = true;
          _isLiveStream = isLive;
          _loadingStatus = '';
          if (!isLive) {
            _position = Duration.zero;
            _duration = Duration.zero;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingStream = false;
          _isSearching = false;
          _loadingStatus = '';
        });
      }
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

  void _openSettings() async {
    await _flutterTts.speak('Opening settings');
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    }
  }

  double _currentVolume = 1.0;
  double _ttsVolumeBeforeMute = 1.0;

  Future<void> _adjustVolume(int direction) async {
    _currentVolume = (_currentVolume + (direction * 0.1)).clamp(0.0, 1.0);
    if (_currentMode == AppMode.youtube) {
      await _audioPlayer.setVolume(_currentVolume);
    } else {
      await _flutterTts.setVolume(_currentVolume);
    }
    _ttsService.speak(_currentVolume > 0.5 ? 'वolume वाढवले' : 'वolume कमी केले');
  }

  Color get _backgroundColor => _backgroundColorAnimation.value ?? _commandBackground;
  Color get _appBarColor => _appBarColorAnimation.value ?? _commandAppBar;
  Color get _containerColor => _containerColorAnimation.value ?? _commandContainer;
  Color get _accentColor => _accentColorAnimation.value ?? _commandAccent;

  @override
  void dispose() {
    _modeAnimationController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _beepPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _modeAnimationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _startListening,
            onLongPress: _toggleMediaPauseResume,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 40),
                    Text(
                      'Double tap anywhere to speak',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: _currentMode == AppMode.command 
                          ? _buildCommandContent()
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
          ),
        );
      },
    );
  }

  void _toggleMediaPauseResume() {
    if (_currentVideo != null) {
      _toggleYouTubePlayPause();
    } else if (_currentMode == AppMode.command) {
      _togglePlayPause();
    }
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
              _currentMode == AppMode.command ? Icons.mic : Icons.play_circle_fill,
              color: _accentColor,
              key: ValueKey(_currentMode),
            ),
            const SizedBox(width: 8),
            Text(
              _currentMode == AppMode.command ? 'Radio Sathi' : 'YouTube',
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
      ],
    );
  }

  Widget _buildCommandContent() {
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
          if (_loadingStatus.isNotEmpty) ...[
            Text(
              _loadingStatus,
              style: TextStyle(
                color: _accentColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(_accentColor),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            _recognizedText.isEmpty
                ? 'Your speech will appear here...'
                : _recognizedText,
            style: TextStyle(
              color: _recognizedText.isEmpty ? Colors.white30 : Colors.white,
              fontSize: 22,
              height: 1.5,
            ),
          ),
          if (_currentVideo != null) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.play_circle_fill, color: _accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Now Playing',
                  style: TextStyle(color: _accentColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isLoadingStream 
                  ? '${_currentVideo!.title}  •  Loading...'
                  : _currentVideo!.title,
              style: TextStyle(
                color: _isLoadingStream ? Colors.white54 : Colors.white, 
                fontSize: 16
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Say "next" or "previous" to navigate queue',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Queue',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  final isCurrentPlaying = video.id == _currentVideo?.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentPlaying ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentPlaying ? Border.all(color: _accentColor, width: 1) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: isCurrentPlaying
                              ? Icon(Icons.play_arrow, color: _accentColor, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                        ),
                        const SizedBox(width: 8),
                        video.thumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  video.thumbnail,
                                  width: 50,
                                  height: 35,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 35,
                                    color: Colors.grey,
                                    child: const Icon(Icons.music_video, color: Colors.white54, size: 20),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 35,
                                color: Colors.grey,
                                child: const Icon(Icons.music_video, color: Colors.white54, size: 20),
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            video.title,
                            style: TextStyle(
                              color: isCurrentPlaying ? _accentColor : Colors.white,
                              fontSize: 13,
                              fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
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
              _isLoadingStream 
                  ? '${_currentVideo!.title}  •  Loading...'
                  : _currentVideo!.title,
              style: TextStyle(
                color: _isLoadingStream ? Colors.white54 : Colors.white, 
                fontSize: 16
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Queue (Say "next" or "previous" to navigate)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  final isCurrentPlaying = video.id == _currentVideo?.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentPlaying ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentPlaying ? Border.all(color: _accentColor, width: 1) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: isCurrentPlaying
                              ? Icon(Icons.play_arrow, color: _accentColor, size: 20)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                        ),
                        const SizedBox(width: 8),
                        video.thumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  video.thumbnail,
                                  width: 50,
                                  height: 35,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 35,
                                    color: Colors.grey,
                                    child: const Icon(Icons.music_video, color: Colors.white54, size: 20),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 35,
                                color: Colors.grey,
                                child: const Icon(Icons.music_video, color: Colors.white54, size: 20),
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            video.title,
                            style: TextStyle(
                              color: isCurrentPlaying ? _accentColor : Colors.white,
                              fontSize: 13,
                              fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
          onDoubleTap: _isListening ? _stopListening : _startListening,
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
        if (_currentVideo != null) ...[
          const SizedBox(width: 40),
          _buildYouTubeControls(),
        ],
      ],
    );
  }

  Widget _buildYouTubeControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLiveStream)
          _buildLiveIndicator()
        else
          _buildProgressBar(),
        const SizedBox(height: 12),
        Row(
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
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _duration.inMilliseconds > 0 
        ? _position.inMilliseconds / _duration.inMilliseconds 
        : 0.0;
    
    return Column(
      children: [
        SizedBox(
          width: 250,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: _accentColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentColor,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * _duration.inMilliseconds).round(),
                );
                _audioPlayer.seek(newPosition);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
          SizedBox(width: 8),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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