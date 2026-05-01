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

  @HiveField(4)
  String? youtubeQuery;

  @HiveField(5)
  String? youtubeLink;

  @HiveField(6)
  String? youtubeChannelHandle;

  Command({
    required this.id,
    required this.startCommand,
    required this.action,
    required this.channelName,
    this.youtubeQuery,
    this.youtubeLink,
    this.youtubeChannelHandle,
  });
}

enum CommandAction {
  aakashwani,
  youtubeSearch,
  youtubePlayLink,
  youtubeLatestLive,
  custom,
}