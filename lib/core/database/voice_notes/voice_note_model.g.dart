// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceNoteModelAdapter extends TypeAdapter<VoiceNoteModel> {
  @override
  final int typeId = 15;

  @override
  VoiceNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceNoteModel(
      voiceNoteId: fields[0] as String?,
      voiceNoteTitle: fields[1] as String,
      audioFilePath: fields[2] as String,
      durationInSeconds: fields[3] as int,
      fileSizeInBytes: fields[4] as int,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      userId: fields[7] as String,
      isSynced: fields[8] as bool,
      isDeleted: fields[9] as bool,
      tags: (fields[10] as List?)?.cast<String>(),
      description: fields[11] as String?,
      deletedAt: fields[12] as DateTime?,
      deletedBy: fields[13] as String?,
      deviceId: fields[14] as String?,
      isDeletionSynced: fields[15] as bool,
      lastSyncAt: fields[16] as DateTime?,
      versionNumber: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceNoteModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.voiceNoteId)
      ..writeByte(1)
      ..write(obj.voiceNoteTitle)
      ..writeByte(2)
      ..write(obj.audioFilePath)
      ..writeByte(3)
      ..write(obj.durationInSeconds)
      ..writeByte(4)
      ..write(obj.fileSizeInBytes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.deletedAt)
      ..writeByte(13)
      ..write(obj.deletedBy)
      ..writeByte(14)
      ..write(obj.deviceId)
      ..writeByte(15)
      ..write(obj.isDeletionSynced)
      ..writeByte(16)
      ..write(obj.lastSyncAt)
      ..writeByte(17)
      ..write(obj.versionNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceNoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
