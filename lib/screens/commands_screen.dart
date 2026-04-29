import 'package:flutter/material.dart';
import '../models/command.dart';
import '../services/hive_service.dart';
import 'command_create_screen.dart';

class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  List<Command> _commands = [];

  @override
  void initState() {
    super.initState();
    _loadCommands();
  }

  void _loadCommands() {
    setState(() {
      _commands = HiveService.getAllCommands();
    });
  }

  void _deleteCommand(String id) async {
    await HiveService.deleteCommand(id);
    _loadCommands();
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
          'Commands',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _commands.isEmpty
          ? const Center(
              child: Text(
                'No commands yet.\nTap + to add one.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _commands.length,
              itemBuilder: (context, index) {
                final command = _commands[index];
                return Card(
                  color: const Color(0xFF16213E),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(
                      command.startCommand,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      '${command.action} - ${command.channelName}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCommand(command.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommandCreateScreen(),
            ),
          );
          _loadCommands();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}