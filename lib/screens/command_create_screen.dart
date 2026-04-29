import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/command.dart';
import '../services/hive_service.dart';

class CommandCreateScreen extends StatefulWidget {
  const CommandCreateScreen({super.key});

  @override
  State<CommandCreateScreen> createState() => _CommandCreateScreenState();
}

class _CommandCreateScreenState extends State<CommandCreateScreen> {
  final _startCommandController = TextEditingController();
  final _channelNameController = TextEditingController();
  String _selectedAction = 'Aakashwani';
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void dispose() {
    _startCommandController.dispose();
    _channelNameController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
    });
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.speak('Say the command');
    await Future.delayed(const Duration(seconds: 2));
    _startCommandController.text = 'Play Vividh Bharti';
    setState(() {
      _isListening = false;
    });
  }

  void _saveCommand() async {
    if (_startCommandController.text.isEmpty || _channelNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final command = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startCommand: _startCommandController.text,
      action: _selectedAction,
      channelName: _channelNameController.text,
    );

    await HiveService.addCommand(command);
    
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
        title: const Text(
          'Create Command',
          style: TextStyle(
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
              'Start Command',
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
                    child: Text('Aakashwani'),
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
            const Text(
              'Channel Name',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _channelNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Vividh Bharti',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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