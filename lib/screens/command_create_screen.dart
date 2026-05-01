import 'package:flutter/material.dart';
import '../models/command.dart';
import '../services/hive_service.dart';
import '../services/webview_service.dart';
import '../services/tts_service.dart';

class CommandCreateScreen extends StatefulWidget {
  final Command? command;
  const CommandCreateScreen({super.key, this.command});

  @override
  State<CommandCreateScreen> createState() => _CommandCreateScreenState();
}

class _CommandCreateScreenState extends State<CommandCreateScreen> {
  final _startCommandController = TextEditingController();
  final _channelSearchController = TextEditingController();
  final _youtubeQueryController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final _youtubeChannelHandleController = TextEditingController();
  String _selectedAction = 'Aakashwani';
  bool _isListening = false;
  bool _isLoadingChannels = false;
  final TtsService _ttsService = TtsService();
  List<String> _filteredChannels = [];
  List<String> _allChannels = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
    if (widget.command != null) {
      _startCommandController.text = widget.command!.startCommand;
      _selectedAction = widget.command!.action;
      if (widget.command!.channelName.isNotEmpty) {
        _channelSearchController.text = widget.command!.channelName;
      }
      if (widget.command!.youtubeQuery != null) {
        _youtubeQueryController.text = widget.command!.youtubeQuery!;
      }
      if (widget.command!.youtubeLink != null) {
        _youtubeLinkController.text = widget.command!.youtubeLink!;
      }
      if (widget.command!.youtubeChannelHandle != null) {
        _youtubeChannelHandleController.text = widget.command!.youtubeChannelHandle!;
      }
    }
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoadingChannels = true;
    });

    await WebViewService.fetchChannelNames();

    if (mounted) {
      setState(() {
        _allChannels = List.from(WebViewService.channelNames);
        _filteredChannels = List.from(_allChannels);
        _isLoadingChannels = false;
      });
    }
  }

  void _filterChannels(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChannels = List.from(_allChannels);
      } else {
        _filteredChannels = _allChannels
            .where((ch) => ch.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _startCommandController.dispose();
    _channelSearchController.dispose();
    _youtubeQueryController.dispose();
    _youtubeLinkController.dispose();
    _youtubeChannelHandleController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
    });
    _startCommandController.text = 'Play Vividh Bharti';
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  void _saveCommand() async {
    if (_startCommandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a command')),
      );
      return;
    }

    if (_selectedAction == 'Aakashwani' && _channelSearchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a channel')),
      );
      return;
    }

    if (_selectedAction == 'YouTube Search' && _youtubeQueryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search query')),
      );
      return;
    }

    if (_selectedAction == 'YouTube Play Link' && _youtubeLinkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube link')),
      );
      return;
    }

    if (_selectedAction == 'YouTube Latest Live' && _youtubeChannelHandleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube channel name or @handle')),
      );
      return;
    }

    String channelName = _selectedAction == 'Aakashwani' ? _channelSearchController.text : '';
    String? youtubeQuery = _selectedAction == 'YouTube Search' ? _youtubeQueryController.text : null;
    String? youtubeLink = _selectedAction == 'YouTube Play Link' ? _youtubeLinkController.text : null;
    String? youtubeChannelHandle = _selectedAction == 'YouTube Latest Live' ? _youtubeChannelHandleController.text : null;

    if (widget.command != null) {
      final updatedCommand = Command(
        id: widget.command!.id,
        startCommand: _startCommandController.text,
        action: _selectedAction,
        channelName: channelName,
        youtubeQuery: youtubeQuery,
        youtubeLink: youtubeLink,
        youtubeChannelHandle: youtubeChannelHandle,
      );
      await HiveService.updateCommand(updatedCommand);
    } else {
      final command = Command(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startCommand: _startCommandController.text,
        action: _selectedAction,
        channelName: channelName,
        youtubeQuery: youtubeQuery,
        youtubeLink: youtubeLink,
        youtubeChannelHandle: youtubeChannelHandle,
      );
      await HiveService.addCommand(command);
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.command != null ? 'Edit Command' : 'Create Command',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Command (what to say)',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCommandController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Play Vividh Bharti',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF16213E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _startListening,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Action',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _selectedAction,
                isExpanded: true,
                dropdownColor: const Color(0xFF16213E),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'Aakashwani',
                    child: Text('Aakashwani (Radio)'),
                  ),
                  DropdownMenuItem(
                    value: 'YouTube Search',
                    child: Text('YouTube Search'),
                  ),
                  DropdownMenuItem(
                    value: 'YouTube Play Link',
                    child: Text('YouTube Play Link'),
                  ),
                  DropdownMenuItem(
                    value: 'YouTube Latest Live',
                    child: Text('YouTube Latest Live'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            if (_selectedAction == 'Aakashwani') ...[
              const Text(
                'Select Channel',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (_isLoadingChannels)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else ...[
                TextField(
                  controller: _channelSearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search channel...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterChannels,
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _filteredChannels.isEmpty
                      ? const Center(
                          child: Text(
                            'No channels found',
                            style: TextStyle(color: Colors.white30),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = _filteredChannels[index];
                            return ListTile(
                              title: Text(
                                channel,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                setState(() {
                                  _channelSearchController.text = channel;
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ],
            if (_selectedAction == 'YouTube Search') ...[
              const Text(
                'YouTube Search Query',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _youtubeQueryController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Latest bhajans',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will search YouTube and play the first result when you say the command.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (_selectedAction == 'YouTube Play Link') ...[
              const Text(
                'YouTube Link (video or playlist)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _youtubeLinkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://youtube.com/watch?v=... or playlist',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste a YouTube video or playlist link. App will play video or queue all playlist videos.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (_selectedAction == 'YouTube Latest Live') ...[
              const Text(
                'YouTube Channel Name or @Handle',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _youtubeChannelHandleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., @bbkivines or BB Ki Vines',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter a YouTube channel name or @handle. App will find the latest live stream or latest video.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save Command',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}