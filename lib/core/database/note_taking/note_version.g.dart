// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_version.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteVersionAdapter extends TypeAdapter<NoteVersion> {
  @override
  final int typeId = 2;

  @override
  NoteVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteVersion(
      versionId: fields[0] as String?,
      noteId: fields[1] as String,
      noteTitle: fields[2] as String,
      noteContent: fields[3] as String,
      tags: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      userId: fields[6] as String,
      changeDescription: fields[7] as String,
      versionNumber: fields[8] as int,
      changes: (fields[9] as List).cast<String>(),
      previousVersionId: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NoteVersion obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.versionId)
      ..writeByte(1)
      ..write(obj.noteId)
      ..writeByte(2)
      ..write(obj.noteTitle)
      ..writeByte(3)
      ..write(obj.noteContent)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.changeDescription)
      ..writeByte(8)
      ..write(obj.versionNumber)
      ..writeByte(9)
      ..write(obj.changes)
      ..writeByte(10)
      ..write(obj.previousVersionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
