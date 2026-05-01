import 'package:hive_flutter/hive_flutter.dart';
import '../models/command.dart';

class HiveService {
  static const String commandsBoxName = 'commands';
  static late Box<Command> _commandsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CommandAdapter());
    _commandsBox = await Hive.openBox<Command>(commandsBoxName);
  }

  static List<Command> getAllCommands() {
    return _commandsBox.values.toList();
  }

  static Future<void> addCommand(Command command) async {
    await _commandsBox.put(command.id, command);
  }

  static Future<void> deleteCommand(String id) async {
    await _commandsBox.delete(id);
  }

  static Future<void> updateCommand(Command command) async {
    await _commandsBox.put(command.id, command);
  }

  static Command? findCommandByStartCommand(String spokenText) {
    final commands = _commandsBox.values.toList();
    for (int i = commands.length - 1; i >= 0; i--) {
      if (spokenText.toLowerCase().contains(commands[i].startCommand.toLowerCase())) {
        return commands[i];
      }
    }
    return null;
  }
}