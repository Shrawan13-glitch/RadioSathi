import 'package:hive/hive.dart';

part 'command.g.dart';

@HiveType(typeId: 0)
class Command extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String startCommand;

  @HiveField(2)
  String action;

  @HiveField(3)
  String channelName;

  Command({
    required this.id,
    required this.startCommand,
    required this.action,
    required this.channelName,
  });
}