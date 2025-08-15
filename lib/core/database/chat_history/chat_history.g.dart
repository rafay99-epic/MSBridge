// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatHistoryAdapter extends TypeAdapter<ChatHistory> {
  @override
  final int typeId = 10;

  @override
  ChatHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHistory(
      id: fields[0] as String,
      title: fields[1] as String,
      messages: (fields[2] as List).cast<ChatHistoryMessage>(),
      createdAt: fields[3] as DateTime,
      lastUpdated: fields[4] as DateTime,
      includePersonal: fields[5] as bool,
      includeMsNotes: fields[6] as bool,
      modelName: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.messages)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.includePersonal)
      ..writeByte(6)
      ..write(obj.includeMsNotes)
      ..writeByte(7)
      ..write(obj.modelName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatHistoryMessageAdapter extends TypeAdapter<ChatHistoryMessage> {
  @override
  final int typeId = 11;

  @override
  ChatHistoryMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHistoryMessage(
      text: fields[0] as String,
      fromUser: fields[1] as bool,
      timestamp: fields[2] as DateTime,
      isError: fields[3] as bool,
      errorDetails: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatHistoryMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.fromUser)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isError)
      ..writeByte(4)
      ..write(obj.errorDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHistoryMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
