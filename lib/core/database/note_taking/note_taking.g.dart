// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_taking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteTakingModelAdapter extends TypeAdapter<NoteTakingModel> {
  @override
  final int typeId = 1;

  @override
  NoteTakingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteTakingModel(
      noteId: fields[0] as String?,
      noteTitle: fields[1] as String,
      noteContent: fields[2] as String,
      isSynced: fields[3] as bool,
      isDeleted: fields[4] as bool,
      updatedAt: fields[5] as DateTime?,
      userId: fields[6] as String,
      tags: (fields[7] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, NoteTakingModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.noteId)
      ..writeByte(1)
      ..write(obj.noteTitle)
      ..writeByte(2)
      ..write(obj.noteContent)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.isDeleted)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTakingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
