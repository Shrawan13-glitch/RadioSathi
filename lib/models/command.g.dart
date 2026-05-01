// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommandAdapter extends TypeAdapter<Command> {
  @override
  final int typeId = 0;

  @override
  Command read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Command(
      id: fields[0] as String,
      startCommand: fields[1] as String,
      action: fields[2] as String,
      channelName: fields[3] as String,
      youtubeQuery: fields[4] as String?,
      youtubeLink: fields[5] as String?,
      youtubeChannelHandle: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Command obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startCommand)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.channelName)
      ..writeByte(4)
      ..write(obj.youtubeQuery)
      ..writeByte(5)
      ..write(obj.youtubeLink)
      ..writeByte(6)
      ..write(obj.youtubeChannelHandle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
