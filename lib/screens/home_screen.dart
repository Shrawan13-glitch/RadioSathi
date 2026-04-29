import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/hive_service.dart';
import '../services/webview_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isListening = false;
  bool _isWebViewVisible = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
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
    final command = HiveService.findCommandByStartCommand(spokenText);
    if (command != null) {
      await _flutterTts.speak('Playing ${command.channelName}');
      await WebViewService.clickChannel(command.channelName);
      setState(() {
        _recognizedText = '';
      });
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

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xFF16213E),
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'Radio Sathi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 40),
              const Text(
                'Tap the mic and speak',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
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
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isListening ? 100 : 80,
                      height: _isListening ? 100 : 80,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Colors.deepPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? Colors.red.withValues(alpha: 0.5)
                                : Colors.deepPurple.withValues(alpha: 0.5),
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
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
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
              ),
              const SizedBox(height: 40),
              if (!_speechEnabled)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Speech recognition not available',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
          Positioned.fill(
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
          ),
        ],
      ),
    );
  }
}