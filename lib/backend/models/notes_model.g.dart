// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MSNoteAdapter extends TypeAdapter<MSNote> {
  @override
  final int typeId = 0;

  @override
  MSNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MSNote(
      id: fields[0] as String,
      lectureTitle: fields[1] as String,
      lectureDescription: fields[2] as String,
      pubDate: fields[3] as String,
      lectureDraft: fields[4] as bool,
      lectureNumber: fields[5] as String,
      subject: fields[6] as String,
      body: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MSNote obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lectureTitle)
      ..writeByte(2)
      ..write(obj.lectureDescription)
      ..writeByte(3)
      ..write(obj.pubDate)
      ..writeByte(4)
      ..write(obj.lectureDraft)
      ..writeByte(5)
      ..write(obj.lectureNumber)
      ..writeByte(6)
      ..write(obj.subject)
      ..writeByte(7)
      ..write(obj.body);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MSNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
